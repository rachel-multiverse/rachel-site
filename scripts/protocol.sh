#!/bin/bash
# Publish the RUBP specification as /protocol, generated from the canonical
# document in the `docs` repo.
#
#   ./scripts/protocol.sh [path-to-docs-repo]
#
# ## Where the source is
#
# `rachel-multiverse/protocol`, public, cloned beside this repo as ../protocol.
# It used to be the private `docs` repo - which is why the `specs/` links in
# the published page pointed at nothing. They are rewritten below to the
# public repository, because a relative link that works in a checkout is a
# 404 on a website.
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

SPEC_REPO="${1:-../protocol}"
SRC="$SPEC_REPO/PROTOCOL.md"
OUT="src/pages/protocol.md"
SPEC_URL="https://github.com/rachel-multiverse/protocol"

if [ ! -f "$SRC" ]; then
  echo "no PROTOCOL.md at $SRC" >&2
  echo "clone it: git clone git@github.com:rachel-multiverse/protocol.git ../protocol" >&2
  exit 1
fi

# The revision is recorded in the page so a reader can tell which version of
# the spec they are looking at, and so a stale copy is visible rather than
# silent.
rev="$(git -C "$SPEC_REPO" rev-parse --short HEAD)"
date="$(git -C "$SPEC_REPO" log -1 --format=%cs -- PROTOCOL.md)"

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
sourceRevision: "$rev"
# Quoted, or YAML reads a bare 2026-07-23 as a timestamp and the page prints
# "2026-07-23T00:00:00" at the foot of the specification.
sourceDate: "$date"
---

EOF
  # `specs/...` resolves inside a checkout of the protocol repo and 404s on
  # the site, where there is no /specs/. These were live for one deploy,
  # pointing at documents PROTOCOL.md calls the authoritative recovery
  # semantics - the ones a port author needs most. Send them to the public
  # repository instead.
  # Directory link first: `[+]` on the file pattern would otherwise still
  # match the bare `specs/` and send a directory to a /blob/ URL.
  sed -E \
    -e "s#\]\(specs/\)#](${SPEC_URL}/tree/main/specs)#g" \
    -e "s#\]\((specs/[^)]+)\)#](${SPEC_URL}/blob/main/\1)#g" \
    "$SRC"
} > "$OUT"

lines=$(wc -l < "$OUT" | tr -d ' ')
echo "  $OUT  $lines lines, from $SPEC_REPO @ $rev ($date)"
