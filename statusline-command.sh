#!/usr/bin/env bash
# Claude Code Status Line
# Zeigt: Modell | Effort | Verzeichnis | Git-Branch | Context | Token | 5h | 7d | Kosten

input=$(cat)
esc=$'\e'

# Punkt als Dezimaltrenner erzwingen. LC_ALL hat hoehere Prioritaet als
# LC_NUMERIC und wird vom System (de_DE.UTF-8) gesetzt – deshalb muss hier
# LC_ALL=C gesetzt werden, sonst bauen awk/printf "200,0k Tok" / "$2,0000".
export LC_ALL=C
export LC_NUMERIC=C

# === Konfiguration ===
# Toggle einzelner Felder ueber die Datei ~/.claude/statusline-config.
# Format: Shell-Variablen (z.B. SHOW_CWD=0). Jeder Wert != 1 blendet aus.
# Die Datei wird hier gesource'd - wenn sie fehlt, greifen die Defaults.
STATUSLINE_CONFIG="${HOME}/.claude/statusline-config"
[ -f "$STATUSLINE_CONFIG" ] && source "$STATUSLINE_CONFIG"
SHOW_CWD="${SHOW_CWD:-1}"   # Verzeichnis
SHOW_GIT="${SHOW_GIT:-1}"   # Git-Branch

# --- Daten aus JSON extrahieren ---
model=$(echo "$input" | jq -r '.model.display_name // "?"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# --- Effort-Level ermitteln ---
# Primaer: effort.level aus dem stdin-JSON (Session-Wert, wird per /effort gesetzt)
# Fallback 1: output_style.name aus dem stdin-JSON (nur wenn nicht "default")
# Fallback 2: Env-Variable CLAUDE_REASONING_EFFORT
# Fallback 3: effortLevel (string) aus settings.json -> direkt als Label
# Fallback 4: reasoning_effort aus settings.json (numerisch -> Label mappen)
effort_label=""
effort_level_json=$(echo "$input" | jq -r '.effort.level // empty')
output_style=$(echo "$input" | jq -r '.output_style.name // empty')
settings_file="$HOME/.claude/settings.json"
if [ -n "$effort_level_json" ]; then
  effort_label="$effort_level_json"
elif [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
  effort_label="$output_style"
elif [ -n "${CLAUDE_REASONING_EFFORT:-}" ]; then
  effort_label="$CLAUDE_REASONING_EFFORT"
elif [ -f "$settings_file" ] && effort_str_cfg=$(jq -r '.effortLevel // empty' "$settings_file" 2>/dev/null) && [ -n "$effort_str_cfg" ]; then
  effort_label="$effort_str_cfg"
elif [ -f "$settings_file" ]; then
  settings_effort=$(jq -r '.reasoning_effort // empty' "$settings_file" 2>/dev/null)
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

# --- Verzeichnis (immer berechnen, fuer user@host:Pfad und Git) ---
home_dir="$HOME"
short_cwd="${cwd/#$home_dir/\~}"
# cwd_str nur als separates Element wenn SHOW_CWD=1 und es wuerde ohnehin
# nicht mehr allein ausgegeben – der Pfad steckt jetzt in userhost_str.
cwd_str=""

# --- Git-Branch (wenn SHOW_GIT=1) ---
git_branch=""
if [ "$SHOW_GIT" = "1" ]; then
  if git_out=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null); then
    [ -n "$git_out" ] && git_branch=" ${esc}[2;33m($git_out)${esc}[0m"
  fi
fi

# --- Session-Kosten schaetzen (Preise Stand 2026, ca.-Werte pro 1M Tokens) ---
# Opus 4.x:   $15 input / $75 output
# Sonnet 4.x: $3 input  / $15 output
# Haiku 4.x:  $1 input  / $5 output
# Hinweis: Cache-Write/Read-Kosten werden nicht berechnet (nur in current_usage,
# nicht als kumulative Felder im stdin-JSON verfuegbar). Werte sind Naeherungen.
model_id=$(echo "$input" | jq -r '.model.id // ""')
if echo "$model_id" | grep -qi "opus"; then
  cost_in=$(awk "BEGIN {printf \"%.4f\", $total_in / 1000000 * 15}")
  cost_out=$(awk "BEGIN {printf \"%.4f\", $total_out / 1000000 * 75}")
elif echo "$model_id" | grep -qi "haiku"; then
  cost_in=$(awk "BEGIN {printf \"%.4f\", $total_in / 1000000 * 1}")
  cost_out=$(awk "BEGIN {printf \"%.4f\", $total_out / 1000000 * 5}")
else
  # Sonnet (Default): $3/$15
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

# --- Context-Usage als Text (Ctx XX%) ---
ctx_str=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    ctx_color="${esc}[2;31m"   # dim Rot
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="${esc}[2;33m"   # dim Gelb
  else
    ctx_color="${esc}[2;32m"   # dim Gruen
  fi
  ctx_str="  ${ctx_color}Ctx ${used_int}%${esc}[0m"
fi

# --- Effort-Anzeige aufbereiten (Magenta, dezent; max/xhigh hell+bold) ---
effort_str=""
if [ -n "$effort_label" ]; then
  case "$effort_label" in
    max|xhigh)
      effort_str="  ${esc}[1;35m[${effort_label}]${esc}[0m" ;;  # Bold Magenta fuer hoechste Stufen
    *)
      effort_str="  ${esc}[2;35m[${effort_label}]${esc}[0m" ;;  # Dim Magenta fuer low/medium/high
  esac
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
    rate_color="${esc}[2;31m"
  elif [ "$rate_pct_int" -ge 70 ]; then
    rate_color="${esc}[2;33m"
  else
    rate_color="${esc}[2m"
  fi
  rate_str="  ${rate_color}5h ${rate_pct_int}% (${reset_str})${esc}[0m"
fi

# --- Rate-Limit (7-Tage-Fenster, nur bei Pro/Max-Abos ab erster API-Antwort) ---
rate7_str=""
rate7_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate7_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$rate7_pct" ] && [ -n "$rate7_reset" ]; then
  rate7_pct_int=$(printf "%.0f" "$rate7_pct")
  # Wochentag (deutsch) + Uhrzeit, z.B. "Do 20:59"
  # macOS (BSD date): -r <ts>; Linux (GNU date): -d "@<ts>". Beide Varianten probieren.
  day_num=$(date -r "$rate7_reset" +%u 2>/dev/null || date -d "@$rate7_reset" +%u 2>/dev/null || echo "")
  case "$day_num" in
    1) day_abbr="Mo" ;;
    2) day_abbr="Di" ;;
    3) day_abbr="Mi" ;;
    4) day_abbr="Do" ;;
    5) day_abbr="Fr" ;;
    6) day_abbr="Sa" ;;
    7) day_abbr="So" ;;
    *) day_abbr="?" ;;
  esac
  time_str=$(date -r "$rate7_reset" +%H:%M 2>/dev/null || date -d "@$rate7_reset" +%H:%M 2>/dev/null || echo "?")
  reset7_str="${day_abbr} ${time_str}"

  if [ "$rate7_pct_int" -ge 90 ]; then
    rate7_color="${esc}[2;31m"
  elif [ "$rate7_pct_int" -ge 70 ]; then
    rate7_color="${esc}[2;33m"
  else
    rate7_color="${esc}[2m"
  fi
  rate7_str="  ${rate7_color}7d ${rate7_pct_int}% (${reset7_str})${esc}[0m"
fi

# --- user@host:Verzeichnis (PS1-Stil, an Position 3 der Status Line) ---
# Format: user@host:~/project  (user@host dim-weiss, Doppelpunkt dim, Pfad dim-blau)
if [ "$SHOW_CWD" = "1" ]; then
  userhost_str="${esc}[2;37m$(whoami)@$(hostname -s)${esc}[0m${esc}[2m:${esc}[0m${esc}[2;34m${short_cwd}${esc}[0m"
else
  userhost_str="${esc}[2;37m$(whoami)@$(hostname -s)${esc}[0m"
fi

# --- Ausgabe zusammenbauen ---
# Reihenfolge: Modell | Effort | user@host:Verzeichnis | Git-Branch | Context | Token | Kosten | 5h | 7d
printf "${esc}[2;36m%s${esc}[0m%s  %s%s%s%s  ${esc}[2m%s${esc}[0m  ${esc}[2m\$%.4f${esc}[0m%s%s\n" \
  "$model" \
  "$effort_str" \
  "$userhost_str" \
  "$cwd_str" \
  "$git_branch" \
  "$ctx_str" \
  "$token_str" \
  "$total_cost" \
  "$rate_str" \
  "$rate7_str"
