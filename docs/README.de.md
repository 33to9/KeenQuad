<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">Scharfe HiDPI-Auflösungen für deinen Monitor, mit einem Klick in der Menüleiste</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="Neueste Version"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="Downloads gesamt"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="Downloads der neuesten Version"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="Lizenz"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <b>Deutsch</b> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <a href="README.es.md">Español</a>
</p>

> **KeenQuad** ist eine kleine Menüleisten-App, die deinen Monitor zwischen HiDPI-Auflösungen umschaltet – auch zu den scharfen, die die Systemeinstellungen nicht anzeigen.
> Bei vielen externen Monitoren gibt es eine Auflösung wie 1600 × 1000 in den Systemeinstellungen nur in der 1x-Version, und die wirkt unscharf. macOS hat auch eine HiDPI-Version davon, die gestochen scharf aussieht, aber umschalten können nur Apps, die die vollständige Liste der Anzeigemodi lesen. Genau das macht KeenQuad, und nicht mehr.

## Warum dieselbe Auflösung unscharf oder scharf sein kann

Jede Größe steht in der Liste der Anzeigemodi von macOS meist zweimal. Bei einem 2560 × 1600-Panel und 1600 × 1000:

| Version | So zeichnet macOS sie | Wirkung |
|---|---|---|
| 1x | Rendert 1600 × 1000 Pixel und streckt sie auf das Panel | Unscharf |
| HiDPI | Rendert 3200 × 2000 Pixel und verkleinert sie auf das Panel | Scharf |

Systemeinstellungen › Displays zeigt nur Modi aus der öffentlichen Schnittstelle, und die verbirgt viele HiDPI-Versionen. Wählst du dort 1600 × 1000, bekommst du die 1x-Version. Ist gerade ein von KeenQuad eingestellter HiDPI-Modus aktiv, zeigen die Systemeinstellungen den gleichnamigen Eintrag als ausgewählt an; klickst du ihn erneut an, wechselst du zur unscharfen Version.

Was gerade aktiv ist, zeigt `system_profiler SPDisplaysDataType`: Bei HiDPI ist **Resolution** doppelt so groß wie **UI Looks like**.

## Funktionen

- Listet alle HiDPI-Auflösungen jedes Monitors auf, auch die verborgenen, und markiert die aktuelle sowie die pixelgenaue Größe des Panels
- Ein Klick schaltet um. Bestätigst du eine neue Auflösung nicht innerhalb von 15 Sekunden, wird sie von selbst zurückgesetzt – ein schwarzer Bildschirm behebt sich also selbst
- Bei einer unscharfen 1x-Auflösung bietet das Menü **Zur scharfen Version wechseln** an, bei gleicher Arbeitsfläche
- Beibehaltene Auflösungen bleiben nach dem Beenden, Abmelden und Neustarten erhalten; macOS speichert sie, im Hintergrund läuft nichts
- Beim Anmelden starten und **Nach Updates suchen …**
- English, 简体中文, 繁體中文, 日本語, Deutsch, 한국어, Français und Español; folgt der Systemsprache, oder du wählst eine im Menü

## Systemvoraussetzungen

- Ein Mac mit Apple Chip
- macOS 14 oder neuer

## Installation

### Option 1: Installation mit einer Zeile (empfohlen, ohne Gatekeeper-Warnung)

Öffne das Terminal, füge diese Zeile ein und drücke den Zeilenschalter:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

Das Skript lädt die neueste Version von GitHub, prüft die SHA-256-Prüfsumme, installiert sie in „Programme“ und öffnet sie. Mit curl geladene Dateien tragen keine Quarantäne-Markierung, daher blockiert macOS den ersten Start nicht. Ist KeenQuad schon installiert, wird es an Ort und Stelle aktualisiert und behält die Einstellung „Beim Anmelden starten“. Das Skript ist kurz – du kannst es gern vorher [lesen](../install.sh).

### Option 2: ZIP

Lade die neueste `KeenQuad_vX.Y.Z_macOS.zip` unter [Releases](https://github.com/33to9/KeenQuad/releases/latest), entpacke sie und bewege KeenQuad in den Ordner „Programme“.

Die App ist nicht von Apple notariell beglaubigt, daher blockiert macOS den ersten Start einmal:
- **macOS 15 und neuer**: Doppelklicken (eine Warnung erscheint), dann **Systemeinstellungen → Datenschutz & Sicherheit** öffnen, nach unten scrollen und auf **Dennoch öffnen** klicken
- **macOS 14**: Mit der rechten Maustaste auf die App klicken → **Öffnen**

### Aktualisieren

Wähle **Nach Updates suchen …** im Menü von KeenQuad. Gibt es eine neue Version, zeigt KeenQuad die Neuerungen und öffnet die Download-Seite. Ohne Gatekeeper-Warnung aktualisierst du, indem du die Installation mit einer Zeile erneut ausführst.

## So benutzt du KeenQuad

Klicke auf das KeenQuad-Symbol in der Menüleiste:

- Ein Klick auf eine Auflösung schaltet um. Bei einer neuen Auflösung fragt KeenQuad **Diese Auflösung beibehalten?** – mit dem Zeilenschalter behältst du sie, mit Esc setzt du sie zurück, nach 15 Sekunden wird sie von selbst zurückgesetzt. Früher beibehaltene Auflösungen werden sofort eingestellt.
- **Zur scharfen Version wechseln** erscheint, wenn die aktuelle Auflösung eine unscharfe 1x-Auflösung mit HiDPI-Version ist.
- **Andere Seitenverhältnisse** enthält HiDPI-Größen, deren Form nicht zum Panel passt.
- **Sprache** und **Beim Anmelden starten** stehen unten im Menü.

## Berechtigungen

Keine. Zum Umschalten der Anzeigemodi braucht KeenQuad weder Bildschirmaufnahme noch Bedienungshilfen oder andere Berechtigungen. Verlangt macOS, das Anmeldeobjekt zu erlauben, öffnet KeenQuad die passende Seite in den Systemeinstellungen.

## Datenschutz

KeenQuad sammelt nichts und hat keine Telemetrie. Es verbindet sich nur mit dem Internet, wenn du auf **Nach Updates suchen …** klickst: eine Anfrage an die GitHub-API nach der neuesten Version, ohne Informationen über dich. Deine Einstellungen liegen in `~/Library/Preferences/com.keenquad.app.plist`.

## Deinstallieren

1. Schalte im Menü von KeenQuad **Beim Anmelden starten** aus und wähle dann **KeenQuad beenden**.
2. Lösche `/Applications/KeenQuad.app`.
3. Optional: Führe `defaults delete com.keenquad.app` aus.

Die aktuelle Auflösung bleibt erhalten; du kannst sie in den Systemeinstellungen ändern.

## So funktioniert es

KeenQuad liest und wechselt die Anzeigemodi über private CoreGraphics-Funktionen (`CGSGetNumberOfDisplayModes`, `CGSGetDisplayModeDescriptionOfLength`, `CGSConfigureDisplayMode`) – dieselben, die das Open-Source-Werkzeug `displayplacer` verwendet. Es erzeugt keine Auflösungen, installiert keine Display-Overrides und fragt nicht nach einem Administratorpasswort; es wechselt nur zu Modi, die macOS bereits hat. Eine neue Auflösung gilt zunächst nur, solange die App läuft; wird KeenQuad sofort beendet, setzt macOS sie zurück. Dauerhaft gespeichert wird sie erst, wenn du sie beibehältst.

Da private Funktionen verwendet werden, könnte ein künftiges macOS-Update sie ändern. Falls das Menü einmal leer bleibt, [erstelle bitte ein Issue](https://github.com/33to9/KeenQuad/issues).

## Aus dem Quellcode erstellen

Voraussetzung: Xcode Command Line Tools (Xcode wird nicht benötigt).

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # erstellen und in /Applications installieren
./Tests/run-selftest.sh     # Regeltests ohne Schreibzugriff, schaltet nichts um
```

`./build.sh --package` erstellt `dist/KeenQuad_vX.Y.Z_macOS.zip` für eine Veröffentlichung. Entwicklernotizen (auf Chinesisch) stehen in [`tray/README.md`](../tray/README.md).

## Lizenz

Dieses Projekt steht unter der **GPL-3.0-only** (siehe [LICENSE](../LICENSE)). Der Name KeenQuad und die Symbole fallen nicht unter die Lizenz; siehe [TRADEMARK.md](../TRADEMARK.md).

Copyright © 2026 [33to9](https://github.com/33to9)
