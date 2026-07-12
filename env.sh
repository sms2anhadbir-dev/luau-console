#!/usr/bin/env bash
# Codespaces environment setup (run in every new shell).
export PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_DIR="$PROJECT_DIR/build"
export PATH="$BUILD_DIR:$PATH"
