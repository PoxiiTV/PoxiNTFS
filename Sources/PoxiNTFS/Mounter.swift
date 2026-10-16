import Foundation

enum MountError: LocalizedError {
    case missingDriver
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingDriver: return "Falta FUSE-T o ntfs-3g. Mira el aviso de arriba."
        case .cancelled: return nil
        case .failed(let message): return message
        }
    }
}

enum Mounter {
    static var driverPath: String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("ntfs-3g/bin/ntfs-3g").path,
            "\(home)/.poxintfs/ntfs-3g/bin/ntfs-3g",
        ].compactMap { $0 }
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static var fuseInstalled: Bool {
        FileManager.default.fileExists(atPath: "/usr/local/lib/libfuse-t.dylib")
    }

    static var toolsReady: Bool { driverPath != nil && fuseInstalled }

    /// Suelta el montaje de solo lectura de macOS (si lo hay) y monta el disco con escritura. Devuelve el punto de montaje.
    static func enableWrite(_ volume: NTFSVolume) throws -> String {
        guard let driver = driverPath, fuseInstalled else { throw MountError.missingDriver }

        if volume.nativeMountPoint != nil,
           Shell.diskutil(["unmount", "/dev/\(volume.device)"]).status != 0 {
            throw MountError.failed("macOS no puede soltar el disco porque algo lo está usando. Cierra los archivos abiertos de ese disco y vuelve a intentarlo.")
        }

        let name = sanitized(volume.name)
        var mountPoint = "/Volumes/\(name)"
        if FileManager.default.fileExists(atPath: mountPoint) { mountPoint += " (NTFS)" }

        let log = NSTemporaryDirectory() + "poxintfs-\(volume.device).log"
        try? FileManager.default.removeItem(atPath: log)
        FileManager.default.createFile(atPath: log, contents: nil, attributes: [.posixPermissions: 0o600])

        let options = "rw,volname=\(name),noappledouble,windows_names,uid=\(getuid()),gid=\(getgid())"
        let command = "/bin/mkdir -p \(quote(mountPoint)) && \(quote(driver)) /dev/\(volume.device) \(quote(mountPoint)) -o \(quote(options)) > \(quote(log)) 2>&1"

        do {
            try runAsAdmin(command, prompt: "PoxiNTFS necesita tu permiso para activar la escritura en \(name).")
        } catch MountError.cancelled {
            throw MountError.cancelled
        } catch {
            let output = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
            throw MountError.failed(friendly(output))
        }
        return mountPoint
    }

    static func eject(_ item: DiskItem) throws {
        switch item.state {
        case .writable(let mountPoint):
            guard Shell.diskutil(["unmount", mountPoint]).status == 0 else { throw busy }
            try? FileManager.default.removeItem(atPath: mountPoint)
        case .readOnly:
            guard Shell.diskutil(["unmount", "/dev/\(item.volume.device)"]).status == 0 else { throw busy }
        case .unmounted:
            break
        }
        _ = Shell.diskutil(["eject", "/dev/\(item.volume.parent)"])
    }

    private static var busy: MountError {
        .failed("No se puede expulsar porque algo está usando el disco. Cierra los archivos abiertos y vuelve a intentarlo.")
    }

    // MARK: - Ayudas

    private static func runAsAdmin(_ command: String, prompt: String) throws {
        let source = "do shell script \"\(escapeAppleScript(command))\" with prompt \"\(escapeAppleScript(prompt))\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        guard let error else { return }
        if (error[NSAppleScript.errorNumber] as? Int) == -128 { throw MountError.cancelled }
        throw MountError.failed(error[NSAppleScript.errorMessage] as? String ?? "Error desconocido")
    }

    private static func friendly(_ output: String) -> String {
        let text = output.lowercased()
        if text.contains("hibernat") || text.contains("fast restart") || text.contains("fast boot") {
            return "Windows dejó este disco \"dormido\" (Inicio rápido). Arranca Windows, apágalo del todo con Mayús + Apagar, o desactiva el Inicio rápido, y vuelve a conectarlo."
        }
        if text.contains("unclean") || text.contains("dirty") || text.contains("not cleanly") || text.contains("inconsisten") {
            return "El disco no se cerró bien la última vez. Conéctalo a Windows y deja que lo compruebe, o ejecuta chkdsk, y vuelve a intentarlo."
        }
        let last = output.split(separator: "\n").last.map(String.init) ?? ""
        return last.isEmpty ? "No se pudo montar el disco." : last
    }

    private static func sanitized(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " _.-"))
        let cleaned = String(name.unicodeScalars.filter { allowed.contains($0) })
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "NTFS" : cleaned
    }

    private static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func escapeAppleScript(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
