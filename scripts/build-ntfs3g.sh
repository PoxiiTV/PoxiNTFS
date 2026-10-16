#!/bin/bash
# Compila ntfs-3g contra FUSE-T y lo instala en la carpeta destino.
# Uso: build-ntfs3g.sh <carpeta con el código fuente> <carpeta destino>
# OJO: la carpeta destino no puede tener espacios (ntfs-3g graba la ruta en el código).
set -euo pipefail

SRC="$1"
PREFIX="$2"

export PATH="/opt/homebrew/bin:/opt/homebrew/opt/libtool/libexec/gnubin:/opt/homebrew/opt/gettext/bin:$PATH"
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PKG_CONFIG_PATH="$HERE/pkgconfig:/usr/local/lib/pkgconfig:/opt/homebrew/lib/pkgconfig"
export CFLAGS="-O2 -I/usr/local/include/fuse"
export LDFLAGS="-L/usr/local/lib"

cd "$SRC"
make distclean >/dev/null 2>&1 || true
./autogen.sh
./configure --prefix="$PREFIX" --exec-prefix="$PREFIX" --with-fuse=external \
    --disable-ldconfig --disable-mount-helper --disable-static
make -j"$(sysctl -n hw.ncpu)"
make install
