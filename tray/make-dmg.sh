#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright © 2026 Pivotfrag LLC
# Builds a drag-to-Applications disk image from a built KeenQuad.app.
# Usage: ./make-dmg.sh <path/to/KeenQuad.app> <output.dmg>
#
# The window layout (background, icon positions) is set through Finder, so the first run may ask
# for permission to control Finder. If that's refused, the image still works, just without the layout.
set -eu

APP="$1"; DMG="$2"
SRC="$(cd "$(dirname "$0")" && pwd)"
VOL="KeenQuad"
# Window and icon geometry, matching Resources/dmg/background.png (660 × 400 points)
W=660; H=400; ICON=128; APP_X=192; APPS_X=468; ICON_Y=210

WORK="$(mktemp -d "${TMPDIR:-/tmp}/keenquad-dmg.XXXXXX")"
ATTACHED=0
trap '[ "$ATTACHED" = 1 ] && hdiutil detach -quiet -force "/Volumes/$VOL" 2>/dev/null; rm -rf "$WORK"' EXIT

STAGE="$WORK/stage"
mkdir -p "$STAGE/.background"
ditto "$APP" "$STAGE/KeenQuad.app"
ln -s /Applications "$STAGE/Applications"
# One TIFF holding the 1x and 2x backgrounds, so the window is sharp on Retina displays
tiffutil -cathidpicheck "$SRC/Resources/dmg/background.png" "$SRC/Resources/dmg/background@2x.png" \
  -out "$STAGE/.background/background.tiff" >/dev/null 2>&1

# Finder addresses the volume by name, so another mounted "KeenQuad" volume would get the layout instead
if [ -d "/Volumes/$VOL" ]; then echo "Eject the mounted \"$VOL\" volume first" >&2; exit 1; fi

hdiutil create -quiet -srcfolder "$STAGE" -volname "$VOL" -fs HFS+ -format UDRW -ov "$WORK/rw.dmg"
hdiutil attach -quiet -readwrite -noverify -noautoopen -mountpoint "/Volumes/$VOL" "$WORK/rw.dmg"
ATTACHED=1

if osascript <<EOF
tell application "Finder"
  tell disk "$VOL"
    open
    set w to container window
    set current view of w to icon view
    set toolbar visible of w to false
    set statusbar visible of w to false
    set bounds of w to {200, 120, 200 + $W, 120 + $H}
    set o to icon view options of w
    set arrangement of o to not arranged
    set icon size of o to $ICON
    set text size of o to 13
    set background picture of o to file ".background:background.tiff"
    set position of item "KeenQuad.app" of w to {$APP_X, $ICON_Y}
    set position of item "Applications" of w to {$APPS_X, $ICON_Y}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF
then echo "DMG layout set"
else echo "Warning: couldn't set the DMG window layout (Finder automation refused?); the image still works" >&2
fi

# Volume icon. Added after mounting and after Finder is done: hdiutil -srcfolder leaves
# .VolumeIcon.icns out, and Finder clears the custom-icon flag while it sets up the window.
cat "$SRC/Resources/KeenQuad.icns" > "/Volumes/$VOL/.VolumeIcon.icns"
SetFile -a C "/Volumes/$VOL"

sync
hdiutil detach -quiet "/Volumes/$VOL"
ATTACHED=0
rm -f "$DMG"
hdiutil convert -quiet "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG"
hdiutil verify -quiet "$DMG"
echo "DMG: $DMG"
