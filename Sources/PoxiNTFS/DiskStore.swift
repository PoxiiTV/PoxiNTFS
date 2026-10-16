import SwiftUI
import AppKit

@MainActor
final class DiskStore: ObservableObject {
    @Published private(set) var disks: [DiskItem] = []
    @Published private(set) var busy: Set<String> = []
    @Published private(set) var errors: [String: String] = [:]
    @Published private(set) var toolsReady = Mounter.toolsReady

    private var task: Task<Void, Never>?

    init() {}

    /// Para las capturas de previsualización, sin tocar el sistema.
    init(preview: [DiskItem], busy: Set<String> = [], errors: [String: String] = [:], toolsReady: Bool = true) {
        self.disks = preview
        self.busy = busy
        self.errors = errors
        self.toolsReady = toolsReady
    }

    var statusText: String {
        if let id = busy.first, let item = disks.first(where: { $0.id == id }) {
            return "Trabajando en \(item.volume.name)…"
        }
        return "Listo"
    }

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func refresh() async {
        let found = await Task.detached { DiskScanner.scan() }.value
        if found != disks { disks = found }
        let ready = Mounter.toolsReady
        if ready != toolsReady { toolsReady = ready }
    }

    func enableWrite(_ item: DiskItem) {
        run(item) { try Mounter.enableWrite(item.volume) }
    }

    func eject(_ item: DiskItem) {
        run(item) { try Mounter.eject(item) }
    }

    func open(_ item: DiskItem) {
        if case .writable(let path) = item.state { NSWorkspace.shared.open(URL(fileURLWithPath: path)) }
    }

    private func run(_ item: DiskItem, _ work: @escaping @Sendable () throws -> some Any) {
        guard !busy.contains(item.id) else { return }
        busy.insert(item.id)
        errors[item.id] = nil
        Task {
            let outcome: Result<Void, Error> = await Task.detached {
                do { _ = try work(); return .success(()) } catch { return .failure(error) }
            }.value
            if case .failure(let error) = outcome {
                if let mountError = error as? MountError, case .cancelled = mountError {
                    // El usuario canceló la contraseña: no es un error.
                } else {
                    errors[item.id] = error.localizedDescription
                }
            }
            busy.remove(item.id)
            await refresh()
        }
    }
}
