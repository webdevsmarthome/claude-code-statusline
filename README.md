# Claude Code Statusline

Eine kompakte, farbige Statusline fuer [Claude Code](https://claude.com/claude-code).

## Anzeige

```
Claude Opus 4.7  [max]  user@host:repo  (main)  Ctx 20%  42k Tok  $0.12  5h 18% (37m)  7d 15% (Do 20:59)
```

Fast alle Farben sind gedimmt (`\e[2;XXm`), damit die Statusline dezent in den Hintergrund tritt und den eigentlichen Prompt-Text nicht ueberstrahlt. Ausnahmen sind der Pfad (hellblau, `CWD_COLOR`) und die Prozentzahlen der Rate-Limits (`RATE_PCT_COLOR`), die zur besseren Lesbarkeit ungedimmt sind. Ausserdem werden die hoechsten Effort-Stufen (`max`/`xhigh`) in **fettem Magenta** hervorgehoben, damit "Maximum Reasoning" auf einen Blick erkennbar ist. Der Multi-Agent-Modus `ultracode` sticht zusaetzlich mit **fettem Hell-Magenta und einem ⚡-Symbol** heraus.

Felder von links nach rechts:

| Feld | Beschreibung |
|---|---|
| **Modell** | Anzeigename des aktiven Modells (cyan) |
| **Effort** | Reasoning-Effort-Level (`low`/`medium`/`high`/`max`/`xhigh`) sowie der Multi-Agent-Modus `ultracode`. `ultracode` ist bold-hell-magenta mit ⚡-Symbol, `max`/`xhigh` bold-magenta, der Rest dim-magenta. Das Matching ist case-unabhaengig (z. B. `Ultracode`), angezeigt wird die Original-Schreibweise. Quelle: `.effort.level` aus dem stdin-JSON (Live-Session-Wert via `/effort`); Fallbacks: `output_style.name`, `CLAUDE_REASONING_EFFORT`-Env, `effortLevel`/`reasoning_effort` aus `~/.claude/settings.json` |
| **user@host:Verzeichnis** | PS1-Stil: Username + Hostname-Shortform + `:` + aktuelles Verzeichnis. Default ist nur der letzte Pfad-Teil (`repo`), damit die Felder rechts sichtbar bleiben; mit `CWD_STYLE=full` der komplette Pfad (`~/projekte/repo`). Home wird als `~` angezeigt. Username/Host dim-weiss, Pfad hellblau (Farbe ueber `CWD_COLOR` anpassbar) |
| **Git-Branch** | In Klammern, nur wenn das Verzeichnis ein Git-Repo ist (gelb) |
| **Context-Usage** | Context-Fenster-Auslastung als Text (`Ctx XX%`), gruen < 50% < gelb < 80% < rot |
| **Token-Verbrauch** | Gesamte Session-Tokens, gedimmt. Unter 1M ganzzahlig in `k` (`69k`), darueber mit einer Nachkommastelle in `M` (`1.2M`) |
| **Session-Kosten** | API-Preis-Schaetzung in USD, gedimmt |
| **Rate-Limit (5h)** | Plan-Auslastung im 5-Stunden-Fenster, Reset relativ (`37m` / `2h 15m`). Farbe: dim < 70% < gelb < 90%; ab 90% Bold-Rot mit ⚠-Warnung. Die Prozentzahl selbst ist nie gedimmt (unter 70% ueber `RATE_PCT_COLOR` anpassbar, darueber in der Warnfarbe) |
| **Rate-Limit (7d)** | Plan-Auslastung im 7-Tage-Fenster, Reset als Wochentag+Uhrzeit (`Do 20:59`). Gleiche Farbschwellen inkl. ⚠-Warnung ab 90% und ungedimmter Prozentzahl (`RATE_PCT_COLOR`) |

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
SHOW_CWD=0       # Verzeichnis-Teil von user@host:Verzeichnis ausblenden -> nur user@host (1 = Default)
SHOW_GIT=0       # Git-Branch ausblenden (1 = anzeigen, Default)
CWD_STYLE=full   # kompletten Pfad statt nur des letzten Pfad-Teils anzeigen (basename = Default)
CWD_COLOR=34     # ANSI-Farbcode des Pfads: 94 = hellblau (Default), 34 = blau, "2;34" = dim-blau, "1;34" = fett-blau, "38;5;208" = 256-Farben-Orange
RATE_PCT_COLOR=97  # Farbe der Prozentzahl in den 5h/7d-Bloecken unter 70%: 0 = normal/ungedimmt (Default), 97 = hellweiss, 96 = hellcyan
```

Alles was nicht in der Datei steht, bleibt beim Default (`SHOW_*=1` = sichtbar, `CWD_STYLE=basename`, `CWD_COLOR=94`, `RATE_PCT_COLOR=0`). Zum Zuruecksetzen einfach die Zeile loeschen.

## Voraussetzungen

- `bash`
- `jq` (wird zur Laufzeit gebraucht)
- `curl` oder `wget` (fuer die Installation)

## Update

Einfach erneut den Installer laufen lassen - er ueberschreibt das Skript und patcht `settings.json` non-destructive.

## Hinweise

- **Kosten sind geschaetzt** basierend auf den Anthropic-API-Preisen pro 1M Tokens (Stand 2026-06):
  - Fable 5: $10 input / $50 output
  - Opus 4.x: $5 input / $25 output (4.6/4.7/4.8; 1M-Kontext ohne Aufpreis)
  - Sonnet 4.x: $3 input / $15 output
  - Haiku 4.x: $1 input / $5 output

  Cache-Write/Read-Kosten werden nicht eingerechnet (sie sind nicht als kumulative Felder im stdin-JSON verfuegbar). Bei Claude Pro/Max zahlst du eine feste Pauschale - die Zahl hier ist ein reiner Orientierungswert.
- **Rate-Limits erscheinen erst nach der ersten API-Antwort** einer Session und sind nur bei Pro/Max-Abos im stdin-JSON enthalten. Fehlen die Felder, werden die entsprechenden Bloecke einfach weggelassen.
- **Locale-Hinweis (Linux mit `LC_ALL=de_DE.UTF-8` o.ae.):** Das Skript setzt intern `LC_ALL=C`, damit `awk`/`printf` Punkt statt Komma als Dezimaltrenner verwenden. Ohne diesen Override entsteht "1,2M Tok", und `printf` verwirft den Kostenwert als ungueltige Zahl, sodass nur noch "$0,00" angezeigt wird.

## Deinstallation

```bash
# Skript entfernen
rm ~/.claude/statusline-command.sh

# statusLine-Eintrag aus settings.json entfernen
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

## Lizenz

[MIT](LICENSE) - frei nutzbar, modifizierbar und weiterverteilbar.
