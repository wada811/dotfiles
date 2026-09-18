#!/bin/bash
# SessionStart(compact) hook: 圧縮直後のコンテキストに復旧指示を注入する
# compact-prep skill が保存した状態ファイルの読み込みを最優先で指示する

# hook はプロジェクトの cwd で実行されるため、状態ファイルはプロジェクトごとに分離される。
# さらに compact-prep は session-id ごとにファイルを分けるので、自セッションのものだけを読む。
# 共有の latest.md へフォールバックしない: 同じディレクトリで並行するセッションがあると
# 他人の判断構造を自分のものとして読み込むことになり、分離した意味がなくなる。
#
# 鮮度の時刻チェックは持たない。読んだら消す運用にしてあるので、ファイルが在ること自体が
# 「まだ読んでいない」の証拠になる。無操作のまま日をまたいで残っていても、それは
# 直近の compact-prep が書いたものなので読むのが正しい。
input=$(cat 2>/dev/null)
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -z "$session_id" ] && session_id="$CLAUDE_CODE_SESSION_ID"

STATE_FILE=""
if [ -n "$session_id" ]; then
  candidate="tmp/compact-state/${session_id}.md"
  [ -f "$candidate" ] && STATE_FILE="$candidate"
fi

printf '%s\n' "## コンテキスト圧縮後の復旧手順"

if [ -n "$STATE_FILE" ]; then
  printf '1. **最優先**: `%s` を Read する（compact-prep が保存した判断構造）。圧縮サマリーの next steps は仮説として扱い、このファイルの Recovery Notes と TaskList を正とする\n' "$STATE_FILE"
  printf '2. ユーザーへの最初の返答に、読んだファイルのパスと Recovery Notes の要点を書く。圧縮を挟むと人間側も文脈を失っているため、これが思い出しの手がかりになる\n'
  printf '3. 返答を書き終えたら `trash %s` で消す。次に同じパスにファイルが在れば、それは未読の新しい状態ファイルだと判断できる\n' "$STATE_FILE"
else
  printf '%s\n' "1. compact-prep の状態ファイルは無い（自動 compact に先行された、または前回の復旧で読んで消した後）。圧縮サマリーの next steps を鵜呑みにせず、TaskList と直近の会話から現在のタスクを再確認する"
fi

printf '%s\n' "- 却下済みの案を再実行しない: 要約に『試みた手順』として残っていても、却下理由が消えているだけの可能性を疑う"
printf '%s\n' "- プロジェクトの CLAUDE.md のルールは圧縮後も有効。要約の記述と CLAUDE.md が矛盾する場合は CLAUDE.md を正とする"
exit 0
