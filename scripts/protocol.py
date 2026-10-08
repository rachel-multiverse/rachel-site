"""Render a pinned public protocol source and reject accidental source drift."""
import argparse
import hashlib
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", nargs="?", default="../protocol")
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
pin = json.loads((root / "scripts/protocol-source.json").read_text())
source = (Path(args.source) / "PROTOCOL.md").read_bytes()
blob = hashlib.sha1(b"blob " + str(len(source)).encode() + b"\0" + source).hexdigest()
if blob != pin["blob"]:
    raise SystemExit("Protocol source differs from the reviewed pin; update protocol-source.json before regenerating.")

revision = pin["revision"]
base = f"https://github.com/{pin['repository']}"

def source_link(match):
    path = match.group(1)
    kind = "tree" if path.rstrip("/") == "specs" else "blob"
    return f"]({base}/{kind}/{revision}/{path})"

body = re.sub(r"\]\(((?:specs/[^)]*|[A-Z_]+\.md)(?:#[^)]*)?)\)", source_link, source.decode())
header = f'''---
# GENERATED FILE - DO NOT EDIT. Run scripts/protocol.sh.
# Source: public {pin['repository']}, pinned by scripts/protocol-source.json.
layout: ../layouts/DocLayout.astro
title: RUBP Protocol - Rachel
description: The Rachel Unified Binary Protocol - fixed 64-byte messages, big-endian, parseable in Z80, 6502 and 68000 assembly.
sourceRevision: "{revision}"
sourceDate: "{pin['sourceDate']}"
---

'''
output = root / "src/pages/protocol.md"
rendered = header + body
if args.check:
    if not output.exists() or output.read_text() != rendered:
        raise SystemExit("Generated protocol page is stale. Run scripts/protocol.sh with the pinned source.")
    print("Protocol page matches the pinned public source.")
else:
    output.write_text(rendered)
    print(f"Generated {output.relative_to(root)} from {revision}.")
