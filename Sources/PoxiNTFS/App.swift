import SwiftUI
import AppKit

struct PoxiNTFSApp: App {
    @StateObject private var store = DiskStore()

    var body: some Scene {
        Window("PoxiNTFS", id: "main") {
            ContentView(store: store)
                .task { store.start() }
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("PoxiNTFS", systemImage: "externaldrive") {
            MenuContent(store: store)
        }
    }
}

private struct MenuContent: View {
    @ObservedObject var store: DiskStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if store.disks.isEmpty {
            Text("No hay discos NTFS conectados")
        }
        ForEach(store.disks) { item in
            switch item.state {
            case .writable:
                Button("Expulsar \(item.volume.name)") { store.eject(item) }
            case .readOnly, .unmounted:
                Button("Activar escritura en \(item.volume.name)") { store.enableWrite(item) }
            }
        }
        Divider()
        Button("Abrir PoxiNTFS") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Salir") { NSApp.terminate(nil) }
    }
}

@main
enum Launcher {
    static func main() {
        let arguments = CommandLine.arguments

        if arguments.contains("--scan") {
            for item in DiskScanner.scan() {
                print("\(item.volume.device)\t\(item.volume.name)\t\(item.state)")
            }
            exit(0)
        }

        // Pruebas desde la terminal: --enable <disco> y --eject <disco>.
        for flag in ["--enable", "--eject"] {
            guard let index = arguments.firstIndex(of: flag), arguments.count > index + 1 else { continue }
            guard let item = DiskScanner.scan().first(where: { $0.id == arguments[index + 1] }) else {
                print("No encuentro el disco NTFS \(arguments[index + 1])"); exit(1)
            }
            do {
                if flag == "--enable" { print("OK \(try Mounter.enableWrite(item.volume))") }
                else { try Mounter.eject(item); print("OK expulsado") }
                exit(0)
            } catch {
                print("ERROR: \(error.localizedDescription)"); exit(1)
            }
        }

        if let index = arguments.firstIndex(of: "--snapshot"), arguments.count > index + 1 {
            MainActor.assumeIsolated { Snapshot.render(to: arguments[index + 1], empty: arguments.contains("--vacio")) }
            exit(0)
        }

        PoxiNTFSApp.main()
    }
}
