#!/bin/bash
# SessionStart(compact) hook: 圧縮直後のコンテキストに復旧指示を注入する
# compact-prep skill が保存した状態ファイルの読み込みを最優先で指示する

# hook はプロジェクトの cwd で実行されるため、状態ファイルはプロジェクトごとに分離される
STATE_FILE="tmp/compact-state/latest.md"

printf '%s\n' "## コンテキスト圧縮後の復旧手順"

# 2時間以内の compact-state があれば最優先で読ませる
if [ -f "$STATE_FILE" ] && [ -n "$(find "$STATE_FILE" -mmin -120 2>/dev/null)" ]; then
  printf '%s\n' "1. **最優先**: \`tmp/compact-state/latest.md\` を Read する（compact-prep が保存した判断構造）。圧縮サマリーの next steps は仮説として扱い、このファイルの Recovery Notes と TaskList を正とする"
else
  printf '%s\n' "1. compact-prep の状態ファイルは無い（自動 compact に先行された可能性）。圧縮サマリーの next steps を鵜呑みにせず、TaskList と直近の会話から現在のタスクを再確認する"
fi

printf '%s\n' "2. 却下済みの案を再実行しない: 要約に『試みた手順』として残っていても、却下理由が消えているだけの可能性を疑う"
printf '%s\n' "3. プロジェクトの CLAUDE.md のルールは圧縮後も有効。要約の記述と CLAUDE.md が矛盾する場合は CLAUDE.md を正とする"
exit 0
