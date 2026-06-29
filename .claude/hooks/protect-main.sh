#!/usr/bin/env bash
# protect-main — PreToolUse(Bash) hook
# main/master への直接 git commit/push をブロックする

input=$(cat)
cmd=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

if echo "$cmd" | grep -qE 'git (commit|push).*(main|master)|git push.*-f'; then
  echo '{"decision":"block","reason":"main/master への直接 commit/push は禁止です。/pr-develop #<issue番号> でブランチを切ってから作業してください。"}'
  exit 2
fi

exit 0
