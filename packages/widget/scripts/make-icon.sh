#!/usr/bin/env bash
set -euo pipefail

# Generates packages/widget/Nudge.icns from a source PNG (>=1024x1024 ideal).
# Usage: scripts/make-icon.sh [path-to-source.png]
# Default source: packages/widget/icon-source/Nudge.png

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_DIR="$(dirname "$SCRIPT_DIR")"
SRC="${1:-$WIDGET_DIR/icon-source/Nudge.png}"
WORK="$WIDGET_DIR/Nudge.iconset"
BASE="$WIDGET_DIR/.icon-1024.png"
OUT="$WIDGET_DIR/Nudge.icns"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: source icon not found: $SRC" >&2
  echo "Provide a square PNG (1024x1024 ideal). Pass a path:" >&2
  echo "  scripts/make-icon.sh /path/to/logo.png" >&2
  exit 1
fi

# Normalize the source to 1024x1024 first.
sips -z 1024 1024 "$SRC" --out "$BASE" >/dev/null

rm -rf "$WORK"
mkdir -p "$WORK"

# iconutil expects exactly these names/sizes.
sips -z 16 16   "$BASE" --out "$WORK/icon_16x16.png"      >/dev/null
sips -z 32 32   "$BASE" --out "$WORK/icon_16x16@2x.png"   >/dev/null
sips -z 32 32   "$BASE" --out "$WORK/icon_32x32.png"      >/dev/null
sips -z 64 64   "$BASE" --out "$WORK/icon_32x32@2x.png"   >/dev/null
sips -z 128 128 "$BASE" --out "$WORK/icon_128x128.png"    >/dev/null
sips -z 256 256 "$BASE" --out "$WORK/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$BASE" --out "$WORK/icon_256x256.png"    >/dev/null
sips -z 512 512 "$BASE" --out "$WORK/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$BASE" --out "$WORK/icon_512x512.png"    >/dev/null
cp "$BASE"      "$WORK/icon_512x512@2x.png"

iconutil -c icns "$WORK" -o "$OUT"
rm -rf "$WORK" "$BASE"
echo "Wrote $OUT"
