#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright © 2026 Pivotfrag LLC
# KeenQuad installer
#
#   curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
#
# Downloads the latest release from GitHub, checks its SHA-256, and installs it to
# /Applications. Files downloaded with curl carry no quarantine flag, so macOS doesn't
# block the first launch. An existing copy is updated in place, which keeps its
# "Launch at Login" setting.
#
# Options (environment variables):
#   KEENQUAD_VERSION=0.4.1   install a specific version instead of the latest
#   KEENQUAD_NO_OPEN=1       don't launch the app after installing
set -euo pipefail

REPO="33to9/KeenQuad"
APP_NAME="KeenQuad.app"
BUNDLE_ID="com.pivotfrag.keenquad"
# 0.4.0 used this bundle ID; a running copy of it has to be quit too.
LEGACY_BUNDLE_ID="com.keenquad.app"
DEST="/Applications/${APP_NAME}"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Everything runs inside main, so a partially downloaded script never executes.
main() {
    [ "$(uname -s)" = "Darwin" ] || fail "KeenQuad only runs on macOS."
    [ "$(uname -m)" = "arm64" ] || fail "KeenQuad requires a Mac with Apple silicon."
    local os_major
    os_major=$(sw_vers -productVersion | cut -d. -f1)
    [ "$os_major" -ge 14 ] || fail "KeenQuad requires macOS 14 or later."

    local api="https://api.github.com/repos/${REPO}/releases/latest"
    [ -n "${KEENQUAD_VERSION:-}" ] && api="https://api.github.com/repos/${REPO}/releases/tags/v${KEENQUAD_VERSION#v}"

    say "Looking up the release…"
    local json
    json=$(curl -fsSL -H "Accept: application/vnd.github+json" "$api") \
        || fail "Could not reach GitHub (${api})."

    local tag url digest
    tag=$(printf '%s' "$json" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
    url=$(printf '%s' "$json" | grep -o '"browser_download_url": *"[^"]*_macOS\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)"$/\1/' || true)
    [ -n "$tag" ] && [ -n "$url" ] || fail "No macOS zip found in release ${tag:-?}."
    # GitHub publishes a sha256 digest per asset; it appears just before its download URL.
    digest=$(printf '%s' "$json" | tr ',' '\n' | grep -E '"digest"|"browser_download_url"' \
        | grep -B1 '_macOS\.zip"' | grep -o 'sha256:[0-9a-f]\{64\}' | head -1 | cut -d: -f2 || true)
    [ -n "$digest" ] || fail "The release has no checksum for the zip."

    # Global (not local): the EXIT trap runs after main has returned.
    tmp=$(mktemp -d)
    trap 'rm -rf "${tmp:-}"' EXIT

    say "Downloading KeenQuad ${tag}…"
    curl -fL --progress-bar -o "$tmp/KeenQuad.zip" "$url" || fail "Download failed."

    local actual
    actual=$(shasum -a 256 "$tmp/KeenQuad.zip" | cut -d' ' -f1)
    [ "$actual" = "$digest" ] || fail "Checksum mismatch (expected ${digest}, got ${actual})."
    say "Checksum OK."

    ditto -x -k "$tmp/KeenQuad.zip" "$tmp/unzipped" || fail "Could not unpack the download."
    local app="$tmp/unzipped/${APP_NAME}"
    [ -d "$app" ] || fail "${APP_NAME} not found in the download."
    # The checksum above is the integrity check; the signature check is informational
    # (the app is ad-hoc signed, not notarized).
    codesign --verify --strict "$app" 2>/dev/null || say "Warning: code signature could not be verified."
    [ "$(defaults read "$app/Contents/Info.plist" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
        || fail "Unexpected bundle identifier."

    # Quit a running copy so it can be replaced. Quitting reverts an unconfirmed resolution.
    if pgrep -xq KeenQuad; then
        say "Quitting the running KeenQuad…"
        local id
        for id in "$BUNDLE_ID" "$LEGACY_BUNDLE_ID"; do
            osascript -e "if application id \"${id}\" is running then tell application id \"${id}\" to quit" >/dev/null 2>&1 || true
        done
        local i
        for i in $(seq 1 20); do pgrep -xq KeenQuad || break; sleep 0.5; done
        pgrep -xq KeenQuad && fail "KeenQuad is still running. Quit it from its menu and try again."
    fi

    # /Applications is writable for admin users; otherwise ask for sudo.
    local sudo=""
    [ -w /Applications ] || sudo="sudo"

    if [ -d "$DEST" ]; then
        # Update in place: deleting the app would make macOS drop its login item.
        say "Updating ${DEST}…"
        $sudo rsync -a --delete "$app/" "$DEST/"
    else
        say "Installing to ${DEST}…"
        $sudo ditto "$app" "$DEST"
    fi
    $sudo xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

    say "KeenQuad ${tag} is installed."
    if [ -z "${KEENQUAD_NO_OPEN:-}" ]; then
        open "$DEST"
        say "Look for the KeenQuad icon in the menu bar."
    fi
}

main "$@"
