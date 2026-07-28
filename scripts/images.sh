#!/bin/bash
# Build the site's images from the App Store screenshot library.
#
#   ./scripts/images.sh [library-dir]
#
# The library is the dated folder that `rachel-ios/scripts/screenshots.sh`
# writes, outside git. This turns the handful the site uses into web-sized
# WebP and drops them in `public/images/`.
#
# Two destinations, deliberately: the library holds full-resolution PNG for
# App Store Connect and is not versioned; the site needs small files and has
# to version them, because the site is built from its repo. A 4MB hero image
# is a bad page whatever it is a picture of - the whole set here is under
# 100KB. See the library's own README for the rest of that reasoning.
#
# Re-run this rather than editing anything in `public/images/` by hand, so
# what the site serves is always what the app rendered.
set -euo pipefail

cd "$(dirname "$0")/.."

LIB="${1:-$HOME/Projects/Rachel/marketing/screenshots/2026-07-28-v1.0}"
OUT="public/images"

if [ ! -d "$LIB" ]; then
  echo "no screenshot library at $LIB" >&2
  echo "run rachel-ios/scripts/screenshots.sh first" >&2
  exit 1
fi

# source-file : output-name : width
# Portrait phone shots are sized to the hero's rendered width; the landscape
# iPad shot is the one wide image on the page and carries more detail.
SHOTS=(
  "iphone-6.9-02-table.png:shot-table:400"
  "iphone-6.9-03-table-card-selected.png:shot-play:400"
  "iphone-6.9-04-tutorial.png:shot-tutorial:400"
  "iphone-6.9-20-host-lobby.png:shot-lobby:400"
  "ipad-13-07-landscape-table.png:emissary-table:1400"
)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for entry in "${SHOTS[@]}"; do
  src="${entry%%:*}"; rest="${entry#*:}"
  name="${rest%%:*}"; width="${rest##*:}"

  if [ ! -f "$LIB/$src" ]; then
    echo "missing $src in $LIB" >&2
    exit 1
  fi

  # Resize first, then encode: cwebp does not resample, and encoding a 2064px
  # PNG down to a 400px box by quality alone is how the set reached 17MB.
  sips --resampleWidth "$width" "$LIB/$src" --out "$tmp/$name.png" > /dev/null
  cwebp -quiet -q 82 "$tmp/$name.png" -o "$OUT/$name.webp"

  printf "  %-22s %s  %sKB\n" "$name.webp" \
    "$(sips -g pixelWidth -g pixelHeight "$OUT/$name.webp" | awk '/pixel/{printf "%sx", $2}' | sed 's/x$//')" \
    "$(( $(stat -f%z "$OUT/$name.webp") / 1024 ))"
done

echo
echo "total: $(( $(cat "$OUT"/*.webp | wc -c) / 1024 ))KB across $(ls "$OUT"/*.webp | wc -l | tr -d ' ') files"
