#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/../.tools"
XCODEGEN="$TOOLS/xcodegen"
VERSION="2.45.4"

if [[ ! -x "$XCODEGEN" ]]; then
  mkdir -p "$TOOLS"
  ARCH="$(uname -m)"
  ZIP="xcodegen.zip"
  URL="https://github.com/yonaskolb/XcodeGen/releases/download/${VERSION}/${ZIP}"
  TMP="$(mktemp -d)"
  curl -fsSL "$URL" -o "$TMP/$ZIP"
  unzip -q "$TMP/$ZIP" -d "$TMP/extract"
  install -m 755 "$TMP/extract/xcodegen/bin/xcodegen" "$XCODEGEN"
  rm -rf "$TMP"
fi

cd "$ROOT"
"$XCODEGEN" generate --spec project.yml
echo "Generated $ROOT/WeddingHQ.xcodeproj"
