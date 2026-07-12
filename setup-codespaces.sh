#!/usr/bin/env bash
# One-time Codespaces setup: installs build tools, clones Luau, preps CMake.
set -euo pipefail

echo "==> Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential cmake git ninja-build

echo "==> Done. Codespaces is ready."
echo ""
echo "==> Next steps:"
echo "    source env.sh"
echo "    mkdir -p build && cd build"
echo "    cmake -G Ninja .."
echo "    cmake --build ."
echo "    ./luauconsole_repl"
