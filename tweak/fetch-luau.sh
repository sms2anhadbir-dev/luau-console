#!/usr/bin/env bash
# Fetches the Luau source into tweak/luau so the Theos Makefile can compile it
# directly into the dylib. Run once before `make package`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -d luau/VM/src ]; then
    echo "==> luau/ already present, skipping. (rm -rf luau to re-fetch)"
    exit 0
fi

echo "==> Cloning Luau (shallow)..."
rm -rf luau
git clone --depth 1 https://github.com/luau-lang/luau.git luau

echo "==> Done. Source dirs:"
echo "    luau/VM/src       ($(ls luau/VM/src/*.cpp | wc -l) files)"
echo "    luau/Compiler/src ($(ls luau/Compiler/src/*.cpp | wc -l) files)"
echo "    luau/Ast/src      ($(ls luau/Ast/src/*.cpp | wc -l) files)"
