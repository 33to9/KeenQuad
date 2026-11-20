#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright © 2026 33to9
# 一条命令构建 KeenQuad.app（6.4）。构建与签名都在内置盘上完成。
# 用法：./build.sh            构建到 ~/Library/Caches/KeenQuad-build/KeenQuad.app
#       ./build.sh --install  构建后原地更新 /Applications/KeenQuad.app
#       ./build.sh --package  构建后打包为 ../dist/KeenQuad_v<版本>_macOS.zip（发布到 GitHub Releases 用）
#       两个选项可以同时使用
set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="${KEENQUAD_BUILD_DIR:-$HOME/Library/Caches/KeenQuad-build}"
# 测试构建（仅供验收脚本使用，不得安装）：KEENQUAD_TEST=1 ./build.sh
EXTRA=""
if [ "${KEENQUAD_TEST:-}" = "1" ]; then
  OUT="$OUT-test"
  EXTRA="-D KEENQUAD_TEST $SRC/Tests/TestHook.swift"
fi
APP="$OUT/KeenQuad.app"

case "$OUT" in
  /Volumes/*) echo "构建目录必须在内置盘上：$OUT" >&2; exit 1 ;;
esac

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# 只复制需要的文件，用 cat 重写以免把 exFAT 的扩展属性 / ._ 伴生文件带进包里
cat "$SRC/Info.plist"                        > "$APP/Contents/Info.plist"
cat "$SRC/Resources/KeenQuad.icns"           > "$APP/Contents/Resources/KeenQuad.icns"
cat "$SRC/Resources/MenuIconTemplate.png"    > "$APP/Contents/Resources/MenuIconTemplate.png"
cat "$SRC/Resources/MenuIconTemplate@2x.png" > "$APP/Contents/Resources/MenuIconTemplate@2x.png"
printf 'APPL????' > "$APP/Contents/PkgInfo"
# 测试构建用独立的 Bundle ID，不碰正式版的登录项记录和偏好设置
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
echo "已构建：$APP"

INSTALL=0; PACKAGE=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --package) PACKAGE=1 ;;
    *) echo "未知选项：$arg" >&2; exit 1 ;;
  esac
done

if [ "$PACKAGE" = "1" ]; then
  if [ "${KEENQUAD_TEST:-}" = "1" ]; then echo "测试构建不得打包" >&2; exit 1; fi
  VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)
  ZIP="$OUT/KeenQuad_v${VERSION}_macOS.zip"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  mkdir -p "$SRC/../dist"
  cat "$ZIP" > "$SRC/../dist/KeenQuad_v${VERSION}_macOS.zip"
  echo "已打包：$SRC/../dist/KeenQuad_v${VERSION}_macOS.zip"
  shasum -a 256 "$ZIP"
fi

if [ "$INSTALL" = "1" ]; then
  if [ "${KEENQUAD_TEST:-}" = "1" ]; then echo "测试构建不得安装" >&2; exit 1; fi
  if pgrep -x KeenQuad >/dev/null; then osascript -e 'quit app id "com.keenquad.app"' || true; sleep 1; fi
  # 原地更新应用包内容，不删除整个 .app：删除后系统会清掉它的登录项记录
  mkdir -p /Applications/KeenQuad.app
  rsync -a --delete "$APP/" /Applications/KeenQuad.app/
  codesign --verify --strict /Applications/KeenQuad.app
  echo "已安装：/Applications/KeenQuad.app"
fi
