#!/bin/bash
# Resize native Saturday validation captures into the site's versioned WebP.
# Usage: ./scripts/images.sh [release-validation-directory]
# Original screenshots remain outside the site repo; no game UI is recreated.
set -euo pipefail
cd "$(dirname "$0")/.."
LIB="${1:-../rachel-ios/fastlane/generated/release-validation/2026-10-01}"
OUT="public/images"
command -v magick >/dev/null || { echo 'Install ImageMagick to resize captures.' >&2; exit 1; }
SHOTS=(
  'ipad-screenshots/02-table.png:shot-table:480'
  'ipad-screenshots/04-tutorial.png:shot-tutorial:480'
  'network-screenshots/20-host-lobby.png:shot-lobby:400'
  'ipad-screenshots/07-landscape-table.png:emissary-table:1400'
  'ipad-screenshots/08-settings.png:shot-settings:480'
)
for entry in "${SHOTS[@]}"; do
  src="${entry%%:*}"; rest="${entry#*:}"; name="${rest%%:*}"; width="${rest##*:}"
  test -f "$LIB/$src" || { echo "Missing capture: $LIB/$src" >&2; exit 1; }
  # Bake orientation before stripping EXIF: simulator landscape PNGs store
  # rotated pixels, so resizing alone can make the web image stand sideways.
  magick "$LIB/$src" -auto-orient -resize "${width}x" -strip -quality 82 "$OUT/$name.webp"
  magick identify -format '%f %wx%h %b\n' "$OUT/$name.webp"
done
ICON_SRC="${ICON_SRC:-../rachel-ios/RachelApp/RachelApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png}"
magick "$ICON_SRC" -resize 512x -strip -quality 90 "$OUT/app-icon.webp"
printf 'Social preview source: scripts/og-card.html (render separately at 1200×630).\n'
