# Claude Code Statusline

Eine kompakte, farbige Statusline fuer [Claude Code](https://claude.com/claude-code).

## Anzeige

```
Claude Opus 4  [max]  ~/projekte/repo (main)  [████░░░░░░░░░░░░░░░░] 20%  42.3k Tok  5h 18% (37m)  $0.1234
```

Felder von links nach rechts:

| Feld | Beschreibung |
|---|---|
| **Modell** | Anzeigename des aktiven Modells (cyan) |
| **Effort** | Reasoning-Effort-Level (`low`/`medium`/`high`/`max`) |
| **Verzeichnis** | Aktuelles Arbeitsverzeichnis, `~` fuer Home (blau) |
| **Git-Branch** | In Klammern, nur wenn das Verzeichnis ein Git-Repo ist (gelb) |
| **Context-Progress-Bar** | 20-Zeichen-Balken, gruen < 50% < gelb < 80% < rot |
| **Token-Verbrauch** | Gesamte Session-Tokens (`k`/`M`-Suffix, gedimmt) |
| **Rate-Limit (5h)** | Plan-Auslastung im 5-Stunden-Fenster mit Reset-Zeit (dim < 70% < gelb < 90% < rot) |
| **Session-Kosten** | API-Preis-Schaetzung in USD, gedimmt |

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/webdevsmarthome/claude-code-statusline/main/install.sh | bash
```

Der Installer:

1. kopiert `statusline-command.sh` nach `~/.claude/statusline-command.sh`
2. patcht `~/.claude/settings.json` (bestehende Settings bleiben erhalten, Backup wird angelegt)
3. setzt den `statusLine`-Eintrag auf den Pfad des Skripts

Nach der Installation: **Claude Code neu starten.**

## Voraussetzungen

- `bash`
- `jq` (wird zur Laufzeit gebraucht)
- `curl` oder `wget` (fuer die Installation)

## Update

Einfach erneut den Installer laufen lassen - er ueberschreibt das Skript und patcht `settings.json` non-destructive.

## Hinweise

- **Kosten sind geschaetzt** basierend auf den Anthropic-API-Preisen (Sonnet: $3/$15 pro MTok, Opus: $15/$75 pro MTok). Bei Claude Pro/Max zahlst du eine feste Pauschale - die Zahl hier ist ein reiner Orientierungswert.
- **Rate-Limit erscheint erst nach der ersten API-Antwort** einer Session und ist nur bei Pro/Max-Abos im stdin-JSON enthalten.

## Deinstallation

```bash
# Skript entfernen
rm ~/.claude/statusline-command.sh

# statusLine-Eintrag aus settings.json entfernen
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```
