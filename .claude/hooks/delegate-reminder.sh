#!/bin/bash
# PostToolUse hook: 親のコンテキストが閾値（既定 150k トークン）を超えたら、一度だけ
# 「重い作業はサブエージェントに出す」を思い出させる。
# CLAUDE.md の規約はセッション後半ほど効き目が薄れるが、親が膨らむのはまさに後半なので、
# 測れる条件で一言だけ注入する。禁止はしない。
# 大きさは transcript 末尾の assistant メッセージの usage（input + cache_creation + cache_read）。
# 一度通知したら marker で止め、compact（post-compact.sh）で再アームする。

threshold="${CLAUDE_DELEGATE_REMIND_TOKENS:-150000}"

input=$(cat)
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""' 2>/dev/null)
transcript=$(printf "%s" "$input" | jq -r '.transcript_path // ""' 2>/dev/null)
{ [ -z "$session_id" ] || [ ! -f "$transcript" ]; } && exit 0

marker="${TMPDIR:-/tmp}/claude-delegate-warned/${session_id}"
[ -f "$marker" ] && exit 0

ctx=$(tail -n 60 "$transcript" \
  | jq -r 'select(.type == "assistant") | .message.usage // empty
           | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)' 2>/dev/null \
  | tail -n 1)
[ -z "$ctx" ] && exit 0
[ "$ctx" -lt "$threshold" ] && exit 0

mkdir -p "$(dirname "$marker")" 2>/dev/null
touch "$marker" 2>/dev/null
k=$((ctx / 1000))
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"## コンテキストが %sk を超えた\\nここから読むものは、以後のすべての呼び出しで読み直される。ビルド・テスト・何度も試す作業・多くのファイルやログを読む調べものは `worker`（Sonnet）、在りかや該当行を探すだけなら `reader`（Haiku）に出し、要約だけを受け取る（~/.claude/CLAUDE.md「サブエージェントへの委譲とモデルの使い分け」）。"}}' "$k"
exit 0
