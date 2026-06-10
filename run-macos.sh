#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  cat <<'EOF'
This helper only runs on macOS.
Use this repository on a Mac to launch the photo viewer.
EOF
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Error: Swift is not installed or not on PATH."
  echo "Install Xcode or the Swift toolchain and retry."
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

echo "Building Dumette..."
swift build

echo "Launching Dumette..."
swift run
