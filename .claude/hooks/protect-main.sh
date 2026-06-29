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

# git commit または git push を含むコマンドのみチェック
if echo "$cmd" | grep -qE 'git (commit|push)'; then
  # force push は常にブロック
  if echo "$cmd" | grep -qE 'git push.*(--force|-f)( |$)'; then
    echo '{"decision":"block","reason":"force push は禁止です。"}'
    exit 2
  fi
  # 現在のブランチ名を取得して main/master ならブロック
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    # dotfiles リポジトリ（~/.dotfiles or ~/dotfiles）は除外
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    case "$repo_root" in
      */dotfiles) exit 0 ;;
    esac
    echo '{"decision":"block","reason":"main/master への直接 commit/push は禁止です。/pr-develop #<issue番号> でブランチを切ってから作業してください。"}'
    exit 2
  fi
fi

exit 0
