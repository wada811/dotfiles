#!/bin/bash
# 狭域 Bash 検査 hook（2026-07-06 再導入、同日レビュー反映）
#
# 経緯: 旧 pre-tool-use-bash.sh は &&連結・for ループ・python3 -c を無差別に
# ブロックし、--permission-mode auto の自動運用で誤爆した（#201 の真因）ため
# テックリード決定で撤去された（5846fd15）。
# 本版はその決定を尊重し、「正当な用途が存在しない」パターンのみ deny する。
# 判断が必要なルール（echo 単独出力・&& 連結など）はここに追加しないこと。
#
# 検知は「コマンド位置」にアンカーする: 行頭・パイプ/セミコロン/& の直後・
# xargs/sudo の直後のみ。コミットメッセージや --body 等の文字列リテラル内に
# "sed -i" 等の語が現れても deny しない（完全な quote 解析はしない設計。
# env プレフィックス経由等のすり抜けは許容し、誤検知ゼロを優先する）。
#
# deny の仕組み: exit 2 + stderr → ツール呼び出しがブロックされ、stderr が
# そのままモデルへのフィードバックになる（自動運用でも1手で自己修正できる）。

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$cmd" ] && exit 0

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

ANCHOR='(^|[|;&]|xargs |sudo )[[:space:]]*'

# git -C: permission allowlist に一致せず承認フローが壊れる（CLAUDE.md 規約）
if printf '%s' "$cmd" | grep -qE "${ANCHOR}git[[:space:]]+-C[[:space:]]"; then
  deny "git -C は使用禁止（permission allowlist に一致しない）。代わりに同一 call 内で改行区切りにする: 1行目 cd <repo>、2行目 git <subcommand>。"
fi

# git filter-branch: 履歴書き換えは git-filter-repo を使う（CLAUDE.md 規約）
if printf '%s' "$cmd" | grep -qE "${ANCHOR}git[[:space:]]+filter-branch"; then
  deny "git filter-branch は使用禁止。git-filter-repo を使う。未インストールなら brew install git-filter-repo を案内する。"
fi

# sed -i / --in-place: ファイル編集は Edit ツールを使う（CLAUDE.md 規約）
if printf '%s' "$cmd" | grep -qE "${ANCHOR}g?sed[[:space:]]+(-i|--in-place)"; then
  deny "sed -i によるファイル編集は禁止。Edit ツールで該当箇所を編集する。"
fi

exit 0
