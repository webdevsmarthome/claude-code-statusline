# Claude Code Statusline

Eine kompakte, farbige Statusline fuer [Claude Code](https://claude.com/claude-code).

## Anzeige

```
Claude Opus 4  [max]  ~/projekte/repo (main)  Ctx 20%  42.3k Tok  5h 18% (37m)  7d 15% (Do 20:59)  $0.1234
```

Alle Farben sind gedimmt (`\e[2;XXm`), damit die Statusline dezent in den Hintergrund tritt und den eigentlichen Prompt-Text nicht ueberstrahlt.

Felder von links nach rechts:

| Feld | Beschreibung |
|---|---|
| **Modell** | Anzeigename des aktiven Modells (cyan) |
| **Effort** | Reasoning-Effort-Level (`low`/`medium`/`high`/`max`) |
| **Verzeichnis** | Aktuelles Arbeitsverzeichnis, `~` fuer Home (blau) |
| **Git-Branch** | In Klammern, nur wenn das Verzeichnis ein Git-Repo ist (gelb) |
| **Context-Usage** | Context-Fenster-Auslastung als Text (`Ctx XX%`), gruen < 50% < gelb < 80% < rot |
| **Token-Verbrauch** | Gesamte Session-Tokens (`k`/`M`-Suffix, gedimmt) |
| **Rate-Limit (5h)** | Plan-Auslastung im 5-Stunden-Fenster, Reset relativ (`37m` / `2h 15m`). Farbe: dim < 70% < gelb < 90% < rot |
| **Rate-Limit (7d)** | Plan-Auslastung im 7-Tage-Fenster, Reset als Wochentag+Uhrzeit (`Do 20:59`). Gleiche Farbschwellen |
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

## Konfiguration (Felder ein-/ausblenden)

Einzelne Felder lassen sich ueber eine optionale Datei `~/.claude/statusline-config` steuern. Sie wird vom Installer **nie** ueberschrieben.

```bash
# ~/.claude/statusline-config
SHOW_CWD=0    # Verzeichnis ausblenden (1 = anzeigen, Default)
SHOW_GIT=0    # Git-Branch ausblenden (1 = anzeigen, Default)
```

Alles was nicht in der Datei steht, bleibt beim Default (`1` = sichtbar). Zum Wiedereinblenden einfach den Wert auf `1` setzen oder die Zeile loeschen.

## Voraussetzungen

- `bash`
- `jq` (wird zur Laufzeit gebraucht)
- `curl` oder `wget` (fuer die Installation)

## Update

Einfach erneut den Installer laufen lassen - er ueberschreibt das Skript und patcht `settings.json` non-destructive.

## Hinweise

- **Kosten sind geschaetzt** basierend auf den Anthropic-API-Preisen (Sonnet: $3/$15 pro MTok, Opus: $15/$75 pro MTok). Bei Claude Pro/Max zahlst du eine feste Pauschale - die Zahl hier ist ein reiner Orientierungswert.
- **Rate-Limits erscheinen erst nach der ersten API-Antwort** einer Session und sind nur bei Pro/Max-Abos im stdin-JSON enthalten. Fehlen die Felder, werden die entsprechenden Blocke einfach weggelassen.

## Deinstallation

```bash
# Skript entfernen
rm ~/.claude/statusline-command.sh

# statusLine-Eintrag aus settings.json entfernen
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

## Lizenz

[MIT](LICENSE) - frei nutzbar, modifizierbar und weiterverteilbar.
