#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright © 2026 Pivotfrag LLC
set -eu
SRC="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${TMPDIR:-/tmp}/keenquad-selftest"
swiftc -O -swift-version 5 -target arm64-apple-macos14.0 -import-objc-header "$SRC/Sources/CGSPrivate.h" \
  "$SRC/Sources/ModeModel.swift" "$SRC/Sources/Strings.swift" "$SRC/Sources/PrivateDisplay.swift" "$SRC/Sources/UpdateChecker.swift" "$SRC/Sources/LoginReminder.swift" \
  "$SRC/Tests/main.swift" -o "$BIN"
"$BIN"
