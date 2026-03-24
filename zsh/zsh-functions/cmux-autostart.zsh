# cmux Main Agent ワークスペースで claude を自動起動
_cmux_autostart() {
  local log="/tmp/cmux-autostart-debug.log"
  echo "[$(date '+%H:%M:%S.%3N')] _cmux_autostart called (PID=$$, SHLVL=$SHLVL, flags=$-)" >> "$log"

  # cmux 外ではスキップ
  if [[ -z "$CMUX_WORKSPACE_ID" ]]; then
    echo "[$(date '+%H:%M:%S.%3N')] skip: CMUX_WORKSPACE_ID is empty" >> "$log"
    return
  fi
  echo "[$(date '+%H:%M:%S.%3N')] CMUX_WORKSPACE_ID=$CMUX_WORKSPACE_ID" >> "$log"

  # 非インタラクティブシェル（claude が実行する bash サブシェルなど）はスキップ
  if [[ "$-" != *i* ]]; then
    echo "[$(date '+%H:%M:%S.%3N')] skip: non-interactive shell" >> "$log"
    return
  fi

  # 現在のワークスペース ref と surface ref を取得 (例: workspace:1, surface:1)
  local ws_ref surface_ref identify_raw
  identify_raw=$(cmux identify 2>&1)
  ws_ref=$(echo "$identify_raw" | jq -r '.caller.workspace_ref // empty' 2>/dev/null)
  surface_ref=$(echo "$identify_raw" | jq -r '.caller.surface_ref // empty' 2>/dev/null)
  echo "[$(date '+%H:%M:%S.%3N')] identify raw=$identify_raw ws_ref=$ws_ref surface_ref=$surface_ref" >> "$log"
  if [[ -z "$ws_ref" ]]; then
    echo "[$(date '+%H:%M:%S.%3N')] skip: ws_ref is empty" >> "$log"
    return
  fi

  # ワークスペースタイトルが "Main Agent" かどうか確認
  local workspaces
  workspaces=$(cmux list-workspaces 2>&1)
  echo "[$(date '+%H:%M:%S.%3N')] list-workspaces=$workspaces" >> "$log"
  if ! echo "$workspaces" | grep -q "${ws_ref}.*Main"; then
    echo "[$(date '+%H:%M:%S.%3N')] skip: not Main workspace" >> "$log"
    return
  fi

  echo "[$(date '+%H:%M:%S.%3N')] launching claude in $(pwd) → cd ~/Documents/work && claude" >> "$log"
  cd ~/Documents/work

  # surface:1 のみ /agents-start を自動送信
  if [[ "$surface_ref" == "surface:1" ]]; then
    (
      sleep 6
      cmux send --workspace "$ws_ref" --surface "surface:1" "/agents-start\n"
      echo "[$(date '+%H:%M:%S.%3N')] sent /agents-start" >> "$log"
    ) &
  else
    echo "[$(date '+%H:%M:%S.%3N')] skip send: not surface:1 ($surface_ref)" >> "$log"
  fi

  claude
  echo "[$(date '+%H:%M:%S.%3N')] claude exited" >> "$log"
}
_cmux_autostart
