#!/usr/bin/env bash
# Installiert die Claude Code Statusline.
#
# One-Liner:
#   curl -fsSL https://raw.githubusercontent.com/webdevsmarthome/claude-code-statusline/main/install.sh | bash
#
# Was passiert:
#   1. Laedt statusline-command.sh nach ~/.claude/statusline-command.sh
#   2. Patcht ~/.claude/settings.json so, dass Claude Code das Skript als Statusline nutzt
#      (bestehende Settings bleiben erhalten, ein Backup wird angelegt)

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/webdevsmarthome/claude-code-statusline/main"
CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DST="${CLAUDE_DIR}/statusline-command.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"

echo "==> Claude Code Statusline Installer"

# --- jq-Check ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Fehler: 'jq' ist nicht installiert, wird aber zur Laufzeit der Statusline benoetigt." >&2
  echo "  Debian/Ubuntu: sudo apt install jq" >&2
  echo "  macOS:         brew install jq" >&2
  echo "  RHEL/Fedora:   sudo dnf install jq" >&2
  exit 1
fi

# --- Verzeichnis sicherstellen ---
mkdir -p "$CLAUDE_DIR"

# --- Skript herunterladen ---
echo "  -> lade statusline-command.sh ..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$REPO_RAW/statusline-command.sh" -o "$SCRIPT_DST"
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "$SCRIPT_DST" "$REPO_RAW/statusline-command.sh"
else
  echo "Fehler: weder 'curl' noch 'wget' gefunden." >&2
  exit 1
fi
chmod +x "$SCRIPT_DST"
echo "     installiert: $SCRIPT_DST"

# --- settings.json vorbereiten ---
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  echo "  -> neue settings.json angelegt"
else
  BACKUP="${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS" "$BACKUP"
  echo "  -> Backup: $BACKUP"
fi

# --- statusLine-Eintrag patchen (non-destructive) ---
TMP=$(mktemp)
jq --arg cmd "$SCRIPT_DST" \
  '.statusLine = {"type":"command","command":$cmd}' \
  "$SETTINGS" > "$TMP"
mv "$TMP" "$SETTINGS"
echo "     statusLine-Eintrag in settings.json aktualisiert"

echo ""
echo "Fertig. Starte Claude Code neu, damit die Statusline geladen wird."
