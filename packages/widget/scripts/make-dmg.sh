#!/usr/bin/env bash
set -euo pipefail

# Builds dist/Nudge-<version>.dmg from dist/Nudge.app using hdiutil only.

VERSION="0.1.0"  # keep in sync with packages/core/pyproject.toml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$WIDGET_DIR/../.." && pwd)"
DIST="$REPO_ROOT/dist"
APP="$DIST/Nudge.app"
STAGING="$DIST/dmg-staging"
DMG="$DIST/Nudge-$VERSION.dmg"

if [[ ! -d "$APP" ]]; then
  echo "ERROR: $APP not found. Run: make app" >&2
  exit 1
fi

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/Nudge.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "Nudge" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG"

rm -rf "$STAGING"
echo "Built $DMG"
