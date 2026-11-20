#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright © 2026 33to9
# Builds KeenQuad.app in one command. Building and signing happen on the internal disk.
# Usage: ./build.sh            build ~/Library/Caches/KeenQuad-build/KeenQuad.app
#        ./build.sh --install  also update /Applications/KeenQuad.app in place
#        ./build.sh --package  also create ../dist/KeenQuad_v<version>_macOS.zip for GitHub Releases
#        The two options can be combined.
set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="${KEENQUAD_BUILD_DIR:-$HOME/Library/Caches/KeenQuad-build}"
# Test build (for testing only, never installed): KEENQUAD_TEST=1 ./build.sh
EXTRA=""
if [ "${KEENQUAD_TEST:-}" = "1" ]; then
  OUT="$OUT-test"
  EXTRA="-D KEENQUAD_TEST $SRC/Tests/TestHook.swift"
fi
APP="$OUT/KeenQuad.app"

case "$OUT" in
  /Volumes/*) echo "The build directory must be on the internal disk: $OUT" >&2; exit 1 ;;
esac

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Copy only what's needed, rewriting with cat so exFAT extended attributes and ._ files stay out of the bundle
cat "$SRC/Info.plist"                        > "$APP/Contents/Info.plist"
cat "$SRC/Resources/KeenQuad.icns"           > "$APP/Contents/Resources/KeenQuad.icns"
cat "$SRC/Resources/MenuIconTemplate.png"    > "$APP/Contents/Resources/MenuIconTemplate.png"
cat "$SRC/Resources/MenuIconTemplate@2x.png" > "$APP/Contents/Resources/MenuIconTemplate@2x.png"
printf 'APPL????' > "$APP/Contents/PkgInfo"
# The test build gets its own bundle ID so it never touches the real app's login item or settings
if [ "${KEENQUAD_TEST:-}" = "1" ]; then
  plutil -replace CFBundleIdentifier -string com.keenquad.app.test "$APP/Contents/Info.plist"
fi

swiftc -O -swift-version 5 -target arm64-apple-macos14.0 \
  -module-name KeenQuad \
  -import-objc-header "$SRC/Sources/CGSPrivate.h" \
  "$SRC"/Sources/[!.]*.swift $EXTRA \
  -o "$APP/Contents/MacOS/KeenQuad"

xattr -cr "$APP"
codesign --force --sign - "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "Built: $APP"

INSTALL=0; PACKAGE=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --package) PACKAGE=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ "$PACKAGE" = "1" ]; then
  if [ "${KEENQUAD_TEST:-}" = "1" ]; then echo "The test build can't be packaged" >&2; exit 1; fi
  VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)
  ZIP="$OUT/KeenQuad_v${VERSION}_macOS.zip"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  mkdir -p "$SRC/../dist"
  cat "$ZIP" > "$SRC/../dist/KeenQuad_v${VERSION}_macOS.zip"
  echo "Packaged: $SRC/../dist/KeenQuad_v${VERSION}_macOS.zip"
  shasum -a 256 "$ZIP"
fi

if [ "$INSTALL" = "1" ]; then
  if [ "${KEENQUAD_TEST:-}" = "1" ]; then echo "The test build can't be installed" >&2; exit 1; fi
  if pgrep -x KeenQuad >/dev/null; then osascript -e 'quit app id "com.keenquad.app"' || true; sleep 1; fi
  # Update the bundle's contents in place: deleting the .app makes macOS drop its login item
  mkdir -p /Applications/KeenQuad.app
  rsync -a --delete "$APP/" /Applications/KeenQuad.app/
  codesign --verify --strict /Applications/KeenQuad.app
  echo "Installed: /Applications/KeenQuad.app"
fi
