# Licencias de terceros

## ntfs-3g (incluido en la app)

PoxiNTFS lleva dentro `ntfs-3g`, `ntfsfix` y `libntfs-3g` de **ntfs-3g 2026.9.28**, sin modificar.

- Proyecto: https://github.com/tuxera/ntfs-3g (Tuxera y colaboradores)
- Licencia: GPL-2.0-or-later (programas) y LGPL-2.0-or-later (libntfs-3g)
- Código fuente exacto: https://github.com/tuxera/ntfs-3g/archive/refs/tags/2026.9.28.tar.gz
  (SHA-256 `8a75293f07bf40df5701d296de32a4cb0e46d6ae135abb4f41b438df9868a390`)
- Cómo se compila: [`scripts/build-ntfs3g.sh`](scripts/build-ntfs3g.sh)

## FUSE-T (no incluido)

PoxiNTFS necesita **FUSE-T**, que instalas tú aparte (`brew install --cask fuse-t`).
No se distribuye con la app. Proyecto y licencia: https://www.fuse-t.org
