#!/bin/bash
# PostCompact hook: 圧縮イベントの記録（注入は SessionStart(compact) hook が担う）
# 注: PostCompact の stdout はコンテキストに注入されない仕様のため、
# ルール再注入は .claude/hooks/session-start-compact.sh（SessionStart matcher=compact）で行う。
# ここでは圧縮が起きた事実だけをログに残す（liveness / 事後分析用）。

# hook はプロジェクトの cwd で実行されるため、ログはプロジェクトごとに分離される
LOG_DIR="tmp/compact-state"
mkdir -p "$LOG_DIR"
printf '%s compacted\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_DIR}/compact-events.log"

# compact-warn-reminder.sh の cooldown をリセット（次に閾値を超えたら再度通知できるように）
input=$(cat)
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""' 2>/dev/null)
[ -z "$session_id" ] && session_id="$CLAUDE_CODE_SESSION_ID"
if [ -n "$session_id" ]; then
  rm -f "${TMPDIR:-/tmp}/claude-compact-warn/${session_id}" "${TMPDIR:-/tmp}/claude-compact-warned/${session_id}" 2>/dev/null
fi
exit 0
