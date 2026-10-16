#!/bin/bash
# Compila PoxiNTFS con swiftc. Las Command Line Tools de este Mac traen un SDK por
# defecto más nuevo que el compilador, así que fijamos el SDK 26.5.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
swiftc -O -parse-as-library -swift-version 5 \
    -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk \
    -target arm64-apple-macosx14.0 \
    Sources/PoxiNTFS/*.swift -o build/PoxiNTFS
