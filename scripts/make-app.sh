#!/bin/bash
# Ensambla build/PoxiNTFS.app con el driver ntfs-3g dentro y firma ad-hoc.
# Requisitos: scripts/build-ntfs3g.sh ya ejecutado (instala en ~/.poxintfs/ntfs-3g) y FUSE-T instalado.
set -euo pipefail
cd "$(dirname "$0")/.."

SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
NTFS="$HOME/.poxintfs/ntfs-3g"
APP=build/PoxiNTFS.app

./scripts/build.sh
rm -rf "$APP" build/icon.iconset
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/ntfs-3g/bin" "$APP/Contents/Resources/ntfs-3g/lib"
cp build/PoxiNTFS "$APP/Contents/MacOS/PoxiNTFS"

# Driver: solo lo necesario, con la librería referida por ruta relativa.
cp "$NTFS/bin/ntfs-3g" "$NTFS/bin/ntfsfix" "$APP/Contents/Resources/ntfs-3g/bin/"
cp "$NTFS/lib/libntfs-3g.91.dylib" "$APP/Contents/Resources/ntfs-3g/lib/"
LIB="@executable_path/../lib/libntfs-3g.91.dylib"
OLD="$NTFS/lib/libntfs-3g.91.dylib"
for bin in ntfs-3g ntfsfix; do
    install_name_tool -change "$OLD" "$LIB" "$APP/Contents/Resources/ntfs-3g/bin/$bin"
done
install_name_tool -id "$LIB" "$APP/Contents/Resources/ntfs-3g/lib/libntfs-3g.91.dylib"

# Icono
swiftc -sdk "$SDK" -target arm64-apple-macosx14.0 scripts/make-icon.swift -o build/make-icon
./build/make-icon build/icon-1024.png
mkdir build/icon.iconset
for s in 16 32 128 256 512; do
    sips -z $s $s build/icon-1024.png --out "build/icon.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) build/icon-1024.png --out "build/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/PoxiNTFS.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>PoxiNTFS</string>
    <key>CFBundleDisplayName</key><string>PoxiNTFS</string>
    <key>CFBundleIdentifier</key><string>dev.alexiis.poxintfs</string>
    <key>CFBundleExecutable</key><string>PoxiNTFS</string>
    <key>CFBundleIconFile</key><string>PoxiNTFS</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Software libre. Incluye ntfs-3g (GPL) de Tuxera.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
echo "Listo: $APP"
