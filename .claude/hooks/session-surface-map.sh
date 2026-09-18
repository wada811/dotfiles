#!/bin/bash
# SessionStart hook: セッション id とターミナル surface の対応を記録する。
#
# 外部プロセス（launchd の idle-compact など）がセッションへキー入力を送るには、
# session id から surface を引く必要がある。しかし対応を後から復元する手段がない:
# セッションの argv に id が載るのは一部の起動経路だけで、macOS では他プロセスの
# 環境変数も読めない。動いているセッション自身に書かせるのが唯一の確実な経路。
#
# cmux が無いマシンでは何もしない。失敗してもセッションの起動を妨げない。

set -u
CMUX="${CMUX_CLAUDE_HOOK_CMUX_BIN:-cmux}"
command -v "$CMUX" >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null)
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -z "$session_id" ] && session_id="${CLAUDE_CODE_SESSION_ID:-}"
[ -z "$session_id" ] && exit 0

identity=$(timeout 5 "$CMUX" identify 2>/dev/null) || exit 0
surface=$(printf "%s" "$identity" | jq -r '.caller.surface_ref // ""' 2>/dev/null)
workspace=$(printf "%s" "$identity" | jq -r '.caller.workspace_ref // ""' 2>/dev/null)
if [ -z "$surface" ] || [ -z "$workspace" ]; then
  exit 0
fi

DIR="${HOME}/.claude/session-surface"
mkdir -p "$DIR" || exit 0
jq -n \
  --arg session "$session_id" \
  --arg surface "$surface" \
  --arg workspace "$workspace" \
  --arg window "$(printf "%s" "$identity" | jq -r '.caller.window_ref // ""' 2>/dev/null)" \
  --arg cwd "$PWD" \
  --arg updatedAt "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  '{sessionId: $session, surface: $surface, workspace: $workspace, window: $window, cwd: $cwd, updatedAt: $updatedAt}' \
  > "${DIR}/${session_id}.json" 2>/dev/null

exit 0
