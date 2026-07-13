#!/bin/sh
# Read stdin
input=$(cat)

# ── Parse JSON fields ──────────────────────────────────────────────────────────
cwd=$(printf "%s" "$input" | jq -r '.workspace.current_dir // .cwd // ""')
proj=$(printf "%s" "$input" | jq -r '.workspace.project_dir // .cwd // ""')
model=$(printf "%s" "$input" | jq -r 'if (.model | type) == "object" then (.model.display_name // "") else (.model // "") end')
ctx_pct_raw=$(printf "%s" "$input" | jq -r '.context_window.used_percentage // 0')
context_window_size=$(printf "%s" "$input" | jq -r '.context_window.context_window_size // 200000')
rate_5h_pct=$(printf "%s" "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0 | floor')
rate_7d_pct=$(printf "%s" "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0 | floor')

# ── cmux workspace / surface info ───────────────────────────────────────────────
# cmux tree | grep "◀ active" でアクティブパスを取得し、メタデータを除去して
# "window:N | workspace:N NAME | pane:N | surface:N NAME" 形式に整形
cmux_workspace_name="" cmux_surface_name="" cmux_workspace_ref="" cmux_surface_ref=""
if command -v cmux >/dev/null 2>&1; then
  # cmux identify で caller（自分自身）の workspace/surface を取得
  # ◀ active（フォーカス中）ではなく呼び出し元 surface を正しく特定する
  identify_json=$(cmux identify 2>/dev/null)
  cmux_workspace_ref=$(printf "%s" "$identify_json" | jq -r '.caller.workspace_ref // ""')
  cmux_surface_ref=$(printf "%s" "$identify_json" | jq -r '.caller.surface_ref // ""')
  if [ -n "$cmux_workspace_ref" ]; then
    caller_tree=$(cmux tree --workspace "$cmux_workspace_ref" 2>/dev/null)
    cmux_workspace_name=$(printf "%s" "$caller_tree" | grep -E " $cmux_workspace_ref " | sed 's/^[^"]*"\([^"]*\)".*/\1/' | head -1)
    cmux_surface_name=$(printf "%s" "$caller_tree" | grep -E " $cmux_surface_ref " | sed 's/^[^"]*"\([^"]*\)".*/\1/' | head -1)
    # 先頭が非 ASCII（スピナー等）なら先頭語を除去: LC_ALL=C で [[:print:]] = ASCII 0x20-0x7E のみ
    cmux_surface_name=$(printf "%s" "$cmux_surface_name" | LC_ALL=C awk '{if(substr($0,1,1)~/[[:print:]]/)print;else{sub(/^[^ ]+ /,"");print}}')
  fi
fi

# ── ANSI colors ─────────────────────────────────────────────────────────────────
reset="\033[0m"
bold="\033[1m"
dim="\033[2m"
cyan="\033[36m"
green="\033[32m"
yellow="\033[33m"
red="\033[31m"

# ── Draw progress bar: draw_bar <used> <total> [width=20] ──────────────────────
draw_bar() {
  awk -v used="$1" -v total="$2" -v width="${3:-20}" 'BEGIN {
    if (total <= 0) { for(i=0;i<width;i++) printf "░"; exit }
    filled = int(used * width / total)
    if (filled > width) filled = width
    for(i=0;i<filled;i++) printf "█"
    for(i=filled;i<width;i++) printf "░"
  }'
}

# ── Format number as K/M ───────────────────────────────────────────────────────
fmt_k() {
  awk -v n="$1" 'BEGIN {
    if(n>=1000000) printf "%.1fM", n/1000000
    else if(n>=1000) printf "%.1fK", n/1000
    else printf "%d", n
  }'
}

# ── Git info ─────────────────────────────────────────────────────────────────
git_branch="" git_root="" git_rel="" git_added="" git_removed=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_check=$(cd "$cwd" && git rev-parse --git-dir 2>/dev/null)
  if [ -n "$git_check" ]; then
    git_branch=$(cd "$cwd" && { git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null; })
    top=$(cd "$cwd" && git rev-parse --show-toplevel 2>/dev/null)
    repo=$(basename "$top")
    rel="${cwd#$top}"
    rel="${rel#/}"
    git_root="$repo"
    git_rel="$rel"
    diff_stat=$(cd "$cwd" && git diff --shortstat HEAD 2>/dev/null)
    if [ -n "$diff_stat" ]; then
      git_added=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
      git_removed=$(printf "%s" "$diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
    fi
  fi
fi

# ── Line 1: Workspace name | Surface name | workspace ref | surface ref ──────────
if [ -n "$cmux_workspace_name" ] || [ -n "$cmux_surface_name" ]; then
  line1=""
  [ -n "$cmux_workspace_name" ] && line1="${cyan}${cmux_workspace_name}${reset}"
  if [ -n "$cmux_surface_name" ]; then
    [ -n "$line1" ] && line1="${line1} ${dim}|${reset} "
    line1="${line1}${cmux_surface_name}"
  fi
  if [ -n "$cmux_workspace_ref" ]; then
    [ -n "$line1" ] && line1="${line1} ${dim}|${reset} "
    line1="${line1}${dim}${cmux_workspace_ref}${reset}"
  fi
  if [ -n "$cmux_surface_ref" ]; then
    [ -n "$line1" ] && line1="${line1} ${dim}|${reset} "
    line1="${line1}${dim}${cmux_surface_ref}${reset}"
  fi
  [ -n "$line1" ] && printf "%b\n" "$line1"
fi

# ── Line 2: launch root | git root dir | current dir | branch | +N/-N ─────────────
# launch root（起動 root / プロジェクト root）は git の内外を問わず常に表示する
line2=""
if [ -n "$proj" ]; then
  case "$proj" in
    "$HOME"/*) proj_disp="~/${proj#"$HOME"/}" ;;
    "$HOME")   proj_disp="~" ;;
    *)         proj_disp="$proj" ;;
  esac
  line2="${cyan}${proj_disp}${reset}"
fi
if [ -n "$git_root" ]; then
  [ -n "$line2" ] && line2="${line2} ${dim}|${reset} "
  line2="${line2}${cyan}${git_root}${reset}"
fi
if [ -n "$git_rel" ]; then
  [ -n "$line2" ] && line2="${line2} ${dim}|${reset} "
  line2="${line2}${cyan}${git_rel}${reset}"
fi
if [ -n "$git_branch" ]; then
  [ -n "$line2" ] && line2="${line2} ${dim}|${reset} "
  line2="${line2}${green}${git_branch}${reset}"
fi
if [ -n "$git_added" ] || [ -n "$git_removed" ]; then
  [ -n "$line2" ] && line2="${line2} ${dim}|${reset} "
  [ -n "$git_added" ]   && line2="${line2}${green}+${git_added}${reset}"
  [ -n "$git_added" ] && [ -n "$git_removed" ] && line2="${line2}${dim}/${reset}"
  [ -n "$git_removed" ] && line2="${line2}${red}-${git_removed}${reset}"
fi
[ -n "$line2" ] && printf "%b\n" "$line2"

# ── Line 3: AI info ([Model] | Context bar) ─────────────────────────────────────
line3=""
[ -n "$model" ] && line3="${bold}${model}${reset}"
ctx_pct=$(printf "%d" "${ctx_pct_raw:-0}" 2>/dev/null || printf "0")

# ── compact 閾値 marker（compact-plus のアイデアを移植: 60%で /compact-prep を促す） ──
# 60% の根拠: 自動compact発火点（90〜95%）から30%程度のマージンを確保（1M context 前提）
session_id=$(printf "%s" "$input" | jq -r '.session_id // ""')
[ -z "$session_id" ] && session_id="$CLAUDE_CODE_SESSION_ID"
if [ -n "$session_id" ] && [ "$ctx_pct" -ge "${COMPACT_WARN_THRESHOLD:-60}" ]; then
  warn_dir="${TMPDIR:-/tmp}/claude-compact-warn"
  mkdir -p "$warn_dir" 2>/dev/null
  touch "${warn_dir}/${session_id}" 2>/dev/null
fi

if [ "$ctx_pct" -gt 0 ]; then
  ctx_used=$(awk -v p="$ctx_pct" -v t="$context_window_size" 'BEGIN{printf "%d", p*t/100}')
  ctx_bar=$(draw_bar "$ctx_pct" 100 10)
  ctx_used_fmt=$(fmt_k "$ctx_used")
  ctx_total_fmt=$(fmt_k "$context_window_size")
  if [ "$ctx_pct" -gt 80 ]; then
    bar_color="$red"
  elif [ "$ctx_pct" -gt 50 ]; then
    bar_color="$yellow"
  else
    bar_color="$green"
  fi
  ctx_str="Context(${ctx_total_fmt}): [${bar_color}${ctx_bar}${reset}] ${bold}[${ctx_pct}%]${reset}"
  if [ -n "$line3" ]; then
    line3="${line3} ${dim}|${reset} ${ctx_str}"
  else
    line3="$ctx_str"
  fi
fi
rate_bar_str() {
  pct=$(printf "%d" "${1:-0}" 2>/dev/null || printf "0")
  if [ "$pct" -gt 80 ]; then c="$red"
  elif [ "$pct" -gt 50 ]; then c="$yellow"
  else c="$green"; fi
  bar=$(draw_bar "$pct" 100 10)
  printf "%s [%s%s%s] %s[%d%%]%s" "$2" "$c" "$bar" "$reset" "$bold" "$pct" "$reset"
}
if [ "$rate_5h_pct" -gt 0 ] || [ "$rate_7d_pct" -gt 0 ]; then
  r5=$(rate_bar_str "$rate_5h_pct" "5h:")
  r7=$(rate_bar_str "$rate_7d_pct" "7d:")
  line3="${line3} ${dim}|${reset} ${r5} ${dim}|${reset} ${r7}"
fi
[ -n "$line3" ] && printf "%b\n" "$line3"
