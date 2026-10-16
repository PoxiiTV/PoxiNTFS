import SwiftUI
import AppKit

/// Genera una captura con datos de ejemplo, sin abrir ventanas ni tocar discos.
@MainActor
enum Snapshot {
    static func render(to path: String, empty: Bool = false) {
        _ = NSApplication.shared

        let usb = NTFSVolume(device: "disk4s1", name: "Fotos viaje", nativeMountPoint: "/Volumes/Fotos viaje",
                             size: 500_000_000_000, parent: "disk4", media: "SanDisk Extreme")
        let hdd = NTFSVolume(device: "disk6s2", name: "Juegos PC", nativeMountPoint: nil,
                             size: 2_000_000_000_000, parent: "disk6", media: "WD Elements")
        let items = [
            DiskItem(volume: usb, state: .readOnly("/Volumes/Fotos viaje")),
            DiskItem(volume: hdd, state: .writable("/Volumes/Juegos PC")),
        ]
        let store = empty ? DiskStore(preview: [], toolsReady: false) : DiskStore(preview: items, errors: [
            "disk4s1": "Windows dejó este disco \"dormido\" (Inicio rápido). Apágalo del todo con Mayús + Apagar y vuelve a conectarlo."
        ])

        let view = ContentView(store: store, scrollable: false).frame(width: 780, height: 640)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            print("No se pudo renderizar"); return
        }
        try? png.write(to: URL(fileURLWithPath: path))
        print("Captura guardada en \(path)")
    }
}
