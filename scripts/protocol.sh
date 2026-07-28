#!/bin/bash
# Publish the RUBP specification as /protocol, generated from the canonical
# document in the `docs` repo.
#
#   ./scripts/protocol.sh [path-to-docs-repo]
#
# ## Why this is generated and not written
#
# `docs/PROTOCOL.md` is the cross-platform source of truth, and the decision
# record `0001-rubp-spec-reconciliation` is binding on it. One of its drift
# triggers is:
#
#   Treating `rachel-ios/docs/` as canonical. It is the parallel tree this
#   decision exists to stop feeding from.
#
# A second copy of the spec pasted into this repo would be a third such tree,
# and the one most likely to be read by strangers - so it is generated, with
# the header below saying where it came from, and never edited here. Editing
# `src/pages/protocol.md` by hand is the mistake this comment exists to
# prevent; the next run overwrites it.
#
# ## Why it is committed rather than built in CI
#
# The site builds in its own GitHub Actions runner, which has no `docs`
# checkout beside it and cannot get one - `docs` is private. So this runs
# locally and the result is committed, the same arrangement `images.sh` uses
# for screenshots: generated from a source outside this repo, versioned here
# because the build needs it.
#
# Run it after any change to `PROTOCOL.md`.
set -euo pipefail

cd "$(dirname "$0")/.."

DOCS="${1:-../docs}"
SRC="$DOCS/PROTOCOL.md"
OUT="src/pages/protocol.md"

if [ ! -f "$SRC" ]; then
  echo "no PROTOCOL.md at $SRC" >&2
  echo "pass the path to the docs repo: ./scripts/protocol.sh ../docs" >&2
  exit 1
fi

# The revision is recorded in the page so a reader can tell which version of
# the spec they are looking at, and so a stale copy is visible rather than
# silent.
rev="$(git -C "$DOCS" rev-parse --short HEAD)"
date="$(git -C "$DOCS" log -1 --format=%cs -- PROTOCOL.md)"

{
  cat <<EOF
---
# GENERATED FILE - DO NOT EDIT
#
# Produced by scripts/protocol.sh from PROTOCOL.md in the docs repo, which is
# the source of truth. Edits here are overwritten on the next run; make them
# there instead.
#
# Source revision: $rev
layout: ../layouts/DocLayout.astro
title: RUBP Protocol - Rachel
description: The Rachel Unified Binary Protocol - fixed 64-byte messages, big-endian, parseable in Z80, 6502 and 68000 assembly. The wire format every Rachel client speaks.
sourceRevision: $rev
sourceDate: $date
---

EOF
  cat "$SRC"
} > "$OUT"

lines=$(wc -l < "$OUT" | tr -d ' ')
echo "  $OUT  $lines lines, from $DOCS @ $rev ($date)"
