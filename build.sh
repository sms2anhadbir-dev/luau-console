#!/usr/bin/env bash
# Build script for Codespaces: configure and compile in one command.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "==> Configuring..."
cmake -G Ninja "$PROJECT_DIR"

echo "==> Building..."
cmake --build .

echo "==> Done."
echo "Run the REPL with: ./luauconsole_repl"
