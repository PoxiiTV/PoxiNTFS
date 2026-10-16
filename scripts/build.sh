#!/bin/bash
# Compila PoxiNTFS con swiftc.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
swiftc -O -parse-as-library -swift-version 5 \
    -target arm64-apple-macosx14.0 \
    Sources/PoxiNTFS/*.swift -o build/PoxiNTFS
