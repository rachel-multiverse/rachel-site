#!/bin/bash
# Generate the public specification at the revision in protocol-source.json.
# Usage: scripts/protocol.sh [path-to-protocol-repo] [--check]
# Update the pin and regenerate this page when accepting a specification change.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/protocol.py "$@"
