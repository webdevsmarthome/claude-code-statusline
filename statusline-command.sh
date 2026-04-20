#!/usr/bin/env bash
# Claude Code Status Line
# Zeigt: Modell | Effort | Verzeichnis | Git-Branch | Progress-Bar | Token | Rate-Limit | Kosten

input=$(cat)
esc=$'\e'

# --- Daten aus JSON extrahieren ---
model=$(echo "$input" | jq -r '.model.display_name // "?"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# --- Effort-Level ermitteln ---
# Primaer: output_style.name aus dem stdin-JSON
# Fallback 1: Env-Variable CLAUDE_REASONING_EFFORT
# Fallback 2: reasoning_effort aus settings.json (numerisch -> Label mappen)
effort_label=""
output_style=$(echo "$input" | jq -r '.output_style.name // empty')
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
  effort_label="$output_style"
else
  settings_effort="${CLAUDE_REASONING_EFFORT:-}"
  if [ -z "$settings_effort" ]; then
    settings_file="$HOME/.claude/settings.json"
    if [ -f "$settings_file" ]; then
      settings_effort=$(jq -r '.reasoning_effort // empty' "$settings_file" 2>/dev/null)
    fi
  fi
  if [ -n "$settings_effort" ]; then
    if [ "$settings_effort" -ge 220 ] 2>/dev/null; then
      effort_label="max"
    elif [ "$settings_effort" -ge 130 ] 2>/dev/null; then
      effort_label="high"
    elif [ "$settings_effort" -ge 50 ] 2>/dev/null; then
      effort_label="medium"
    else
      effort_label="low"
    fi
  fi
fi

# --- Verzeichnis kuerzen (Home ersetzen durch ~) ---
home_dir="$HOME"
short_cwd="${cwd/#$home_dir/\~}"

# --- Git-Branch ermitteln ---
git_branch=""
if git_out=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null); then
  [ -n "$git_out" ] && git_branch=" ${esc}[0;33m($git_out)${esc}[0m"
fi

# --- Session-Kosten schaetzen (claude-sonnet/opus Preise, ca.-Werte) ---
# Sonnet: $3/MTok input, $15/MTok output
# Opus:   $15/MTok input, $75/MTok output
model_id=$(echo "$input" | jq -r '.model.id // ""')
if echo "$model_id" | grep -qi "opus"; then
  cost_in=$(awk "BEGIN {printf \"%.4f\", $total_in / 1000000 * 15}")
  cost_out=$(awk "BEGIN {printf \"%.4f\", $total_out / 1000000 * 75}")
else
  cost_in=$(awk "BEGIN {printf \"%.4f\", $total_in / 1000000 * 3}")
  cost_out=$(awk "BEGIN {printf \"%.4f\", $total_out / 1000000 * 15}")
fi
total_cost=$(awk "BEGIN {printf \"%.4f\", $cost_in + $cost_out}")

# --- Token-Verbrauch formatieren ---
total_tokens=$(( total_in + total_out ))
if [ "$total_tokens" -lt 1000 ]; then
  token_str="${total_tokens} Tok"
elif [ "$total_tokens" -lt 1000000 ]; then
  token_str=$(awk "BEGIN {printf \"%.1fk Tok\", $total_tokens / 1000}")
else
  token_str=$(awk "BEGIN {printf \"%.2fM Tok\", $total_tokens / 1000000}")
fi

# --- Context-Progress-Bar ---
bar=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  bar_width=20
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))

  if [ "$used_int" -ge 80 ]; then
    bar_color="${esc}[0;31m"   # Rot
  elif [ "$used_int" -ge 50 ]; then
    bar_color="${esc}[0;33m"   # Gelb
  else
    bar_color="${esc}[0;32m"   # Gruen
  fi

  bar_filled=$(printf '%0.s█' $(seq 1 $filled) 2>/dev/null || printf '=%.0s' $(seq 1 $filled))
  bar_empty=$(printf '%0.s░' $(seq 1 $empty) 2>/dev/null || printf '-%.0s' $(seq 1 $empty))
  bar=" ${bar_color}[${bar_filled}${bar_empty}]${esc}[0m ${used_int}%"
fi

# --- Effort-Anzeige aufbereiten (Magenta, dezent) ---
effort_str=""
if [ -n "$effort_label" ]; then
  effort_str="  ${esc}[0;35m[${effort_label}]${esc}[0m"
fi

# --- Rate-Limit (5h-Fenster, nur bei Pro/Max-Abos ab erster API-Antwort) ---
rate_str=""
rate_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$rate_pct" ] && [ -n "$rate_reset" ]; then
  rate_pct_int=$(printf "%.0f" "$rate_pct")
  now=$(date +%s)
  remaining=$(( rate_reset - now ))
  if [ "$remaining" -lt 0 ]; then
    reset_str="jetzt"
  elif [ "$remaining" -lt 3600 ]; then
    reset_str="$(( remaining / 60 ))m"
  else
    hours=$(( remaining / 3600 ))
    mins=$(( (remaining % 3600) / 60 ))
    reset_str="${hours}h ${mins}m"
  fi

  # Farbe je nach Auslastung: dim < 70% < gelb < 90% < rot
  if [ "$rate_pct_int" -ge 90 ]; then
    rate_color="${esc}[0;31m"
  elif [ "$rate_pct_int" -ge 70 ]; then
    rate_color="${esc}[0;33m"
  else
    rate_color="${esc}[2m"
  fi
  rate_str="  ${rate_color}5h ${rate_pct_int}% (${reset_str})${esc}[0m"
fi

# --- Ausgabe zusammenbauen ---
# Reihenfolge: Modell | Effort | Verzeichnis | Git-Branch | Progress-Bar | Token | Rate-Limit | Kosten
printf "${esc}[0;36m%s${esc}[0m%s  ${esc}[0;34m%s${esc}[0m%s%s  ${esc}[2m%s${esc}[0m%s  ${esc}[2m\$%.4f${esc}[0m\n" \
  "$model" \
  "$effort_str" \
  "$short_cwd" \
  "$git_branch" \
  "$bar" \
  "$token_str" \
  "$rate_str" \
  "$total_cost"
