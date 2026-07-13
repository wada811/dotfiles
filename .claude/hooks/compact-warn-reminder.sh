#!/bin/bash
# UserPromptSubmit hook: context使用率が閾値(既定60%)を超えたら /compact-prep を促す
# compact-plus（github.com/u-ichi/compact-plus）の「60%通知」を移植したもの。
# producer（閾値判定→marker書き込み）は statusline-command.sh が担う。
# 一度通知したら warned marker で cooldown し、次の compact（post-compact.sh）で
# warn/warned 両方の marker をクリアして再アーム可能にする。

input=$(cat)
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -z "$session_id" ] && session_id="$CLAUDE_CODE_SESSION_ID"
[ -z "$session_id" ] && exit 0

warn_marker="${TMPDIR:-/tmp}/claude-compact-warn/${session_id}"
warned_marker="${TMPDIR:-/tmp}/claude-compact-warned/${session_id}"

if [ -f "$warn_marker" ] && [ ! -f "$warned_marker" ]; then
  mkdir -p "$(dirname "$warned_marker")" 2>/dev/null
  touch "$warned_marker" 2>/dev/null
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"## コンテキスト使用率が閾値を超過\ncontext使用率が60%を超えました。自動compactに先を越される前に、区切りの良いところで `/compact-prep` → `/compact` の実行を検討してください（設計原則・却下済み手順の消失を防ぐため）。"}}'
fi
exit 0
