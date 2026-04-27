# Claude Code Statusline

Eine kompakte, farbige Statusline fuer [Claude Code](https://claude.com/claude-code).

## Anzeige

```
Claude Opus 4.7  [max]  user@host:~/projekte/repo  (main)  Ctx 20%  42.3k Tok  $0.1234  5h 18% (37m)  7d 15% (Do 20:59)
```

Alle Farben sind gedimmt (`\e[2;XXm`), damit die Statusline dezent in den Hintergrund tritt und den eigentlichen Prompt-Text nicht ueberstrahlt. Lediglich die hoechsten Effort-Stufen (`max`/`xhigh`) werden in **fettem Magenta** hervorgehoben, damit "Maximum Reasoning" auf einen Blick erkennbar ist.

Felder von links nach rechts:

| Feld | Beschreibung |
|---|---|
| **Modell** | Anzeigename des aktiven Modells (cyan) |
| **Effort** | Reasoning-Effort-Level (`low`/`medium`/`high`/`max`/`xhigh`). `max` und `xhigh` sind bold-magenta, der Rest dim-magenta. Quelle: `.effort.level` aus dem stdin-JSON (Live-Session-Wert via `/effort`); Fallbacks: `output_style.name`, `CLAUDE_REASONING_EFFORT`-Env, `effortLevel`/`reasoning_effort` aus `~/.claude/settings.json` |
| **user@host:Verzeichnis** | PS1-Stil: Username + Hostname-Shortform + `:` + aktuelles Verzeichnis (`~` fuer Home). Username/Host dim-weiss, Pfad dim-blau |
| **Git-Branch** | In Klammern, nur wenn das Verzeichnis ein Git-Repo ist (gelb) |
| **Context-Usage** | Context-Fenster-Auslastung als Text (`Ctx XX%`), gruen < 50% < gelb < 80% < rot |
| **Token-Verbrauch** | Gesamte Session-Tokens (`k`/`M`-Suffix, gedimmt) |
| **Session-Kosten** | API-Preis-Schaetzung in USD, gedimmt |
| **Rate-Limit (5h)** | Plan-Auslastung im 5-Stunden-Fenster, Reset relativ (`37m` / `2h 15m`). Farbe: dim < 70% < gelb < 90% < rot |
| **Rate-Limit (7d)** | Plan-Auslastung im 7-Tage-Fenster, Reset als Wochentag+Uhrzeit (`Do 20:59`). Gleiche Farbschwellen |

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
SHOW_CWD=0    # Verzeichnis-Teil von user@host:Verzeichnis ausblenden -> nur user@host (1 = Default)
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

- **Kosten sind geschaetzt** basierend auf den Anthropic-API-Preisen pro 1M Tokens (Stand 2026):
  - Opus 4.x: $15 input / $75 output
  - Sonnet 4.x: $3 input / $15 output
  - Haiku 4.x: $1 input / $5 output

  Cache-Write/Read-Kosten werden nicht eingerechnet (sie sind nicht als kumulative Felder im stdin-JSON verfuegbar). Bei Claude Pro/Max zahlst du eine feste Pauschale - die Zahl hier ist ein reiner Orientierungswert.
- **Rate-Limits erscheinen erst nach der ersten API-Antwort** einer Session und sind nur bei Pro/Max-Abos im stdin-JSON enthalten. Fehlen die Felder, werden die entsprechenden Bloecke einfach weggelassen.
- **Locale-Hinweis (Linux mit `LC_ALL=de_DE.UTF-8` o.ae.):** Das Skript setzt intern `LC_ALL=C`, damit `awk`/`printf` Punkt statt Komma als Dezimaltrenner verwenden. Ohne diesen Override entstehen "200,0k Tok" / "$2,0000" und Folge-Berechnungen schlagen fehl.

## Deinstallation

```bash
# Skript entfernen
rm ~/.claude/statusline-command.sh

# statusLine-Eintrag aus settings.json entfernen
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

## Lizenz

[MIT](LICENSE) - frei nutzbar, modifizierbar und weiterverteilbar.
