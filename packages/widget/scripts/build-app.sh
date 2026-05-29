#!/usr/bin/env bash
set -euo pipefail

# Builds dist/Nudge.app (universal, ad-hoc signed) from the SwiftPM target.
# Requires: swift, codesign. Run from anywhere (paths resolved absolutely).

VERSION="0.1.0"  # keep in sync with packages/core/pyproject.toml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$WIDGET_DIR/../.." && pwd)"
DIST="$REPO_ROOT/dist"
APP="$DIST/Nudge.app"
ICNS="$WIDGET_DIR/Nudge.icns"
PLIST="$WIDGET_DIR/Info.plist"

ARCH_FLAGS=(--arch arm64 --arch x86_64)

if [[ ! -f "$ICNS" ]]; then
  echo "ERROR: $ICNS missing. Run: make icon" >&2
  exit 1
fi
if [[ ! -f "$PLIST" ]]; then
  echo "ERROR: $PLIST missing." >&2
  exit 1
fi

echo "==> swift build (release, universal)"
if ! swift build --package-path "$WIDGET_DIR" -c release "${ARCH_FLAGS[@]}"; then
  echo "WARNING: universal build failed; falling back to arm64-only" >&2
  ARCH_FLAGS=(--arch arm64)
  swift build --package-path "$WIDGET_DIR" -c release "${ARCH_FLAGS[@]}"
fi

BIN="$(swift build --package-path "$WIDGET_DIR" -c release "${ARCH_FLAGS[@]}" --show-bin-path)/NudgeWidget"
if [[ ! -f "$BIN" ]]; then
  echo "ERROR: built binary not found at $BIN" >&2
  exit 1
fi

echo "==> assembling $APP"
mkdir -p "$DIST"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Nudge"
chmod +x "$APP/Contents/MacOS/Nudge"
cp "$ICNS" "$APP/Contents/Resources/Nudge.icns"
cp "$PLIST" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Validate the plist early — catches typos before signing.
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Prefer a stable self-signed identity (see make-signing-cert.sh) so macOS keeps
# the microphone permission across rebuilds. Fall back to ad-hoc signing.
SIGN_ID="Nudge Dev"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
  echo "==> codesign with '$SIGN_ID' (stable identity)"
  codesign --force --deep --sign "$SIGN_ID" "$APP"
else
  echo "==> ad-hoc codesign (run 'make signing-cert' once for stable permissions)"
  codesign --force --deep --sign - "$APP"
fi
codesign --verify --verbose "$APP" || true

echo "Built $APP (v$VERSION)"
echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/Nudge" 2>/dev/null || echo unknown)"
