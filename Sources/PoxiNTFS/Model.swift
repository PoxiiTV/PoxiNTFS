import Foundation

struct NTFSVolume: Equatable, Identifiable {
    var id: String { device }
    let device: String
    let name: String
    let nativeMountPoint: String?
    let size: Int64
    let parent: String
    let media: String
}

enum MountState: Equatable {
    case unmounted
    case readOnly(String)
    case writable(String)
}

struct DiskItem: Equatable, Identifiable {
    let volume: NTFSVolume
    let state: MountState
    var id: String { volume.device }
}

enum Shell {
    @discardableResult
    static func run(_ path: String, _ arguments: [String]) -> (status: Int32, output: Data) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return (-1, Data()) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, data)
    }

    static func diskutil(_ arguments: [String]) -> (status: Int32, output: Data) {
        run("/usr/sbin/diskutil", arguments)
    }
}

enum DiskScanner {
    static func scan() -> [DiskItem] {
        let mounts = ntfs3gMounts()
        return volumes().map { volume in
            if let mountPoint = mounts[volume.device] { return DiskItem(volume: volume, state: .writable(mountPoint)) }
            if let native = volume.nativeMountPoint { return DiskItem(volume: volume, state: .readOnly(native)) }
            return DiskItem(volume: volume, state: .unmounted)
        }
    }

    static func volumes() -> [NTFSVolume] {
        let list = Shell.diskutil(["list", "-plist"])
        guard list.status == 0, let root = plist(list.output),
              let disks = root["AllDisksAndPartitions"] as? [[String: Any]] else { return [] }

        var identifiers: [String] = []
        for disk in disks {
            if let partitions = disk["Partitions"] as? [[String: Any]] {
                identifiers += partitions.compactMap { $0["DeviceIdentifier"] as? String }
            } else if let id = disk["DeviceIdentifier"] as? String {
                identifiers.append(id)
            }
        }
        return identifiers.compactMap(volume(for:))
    }

    static func volume(for identifier: String) -> NTFSVolume? {
        let result = Shell.diskutil(["info", "-plist", identifier])
        guard result.status == 0, let info = plist(result.output) else { return nil }

        let filesystem = (info["FilesystemType"] as? String)?.lowercased() ?? ""
        let content = info["Content"] as? String ?? ""
        guard filesystem == "ntfs" || content == "Windows_NTFS" else { return nil }

        return NTFSVolume(
            device: identifier,
            name: info["VolumeName"] as? String ?? "Sin nombre",
            nativeMountPoint: (info["MountPoint"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            size: (info["TotalSize"] as? NSNumber)?.int64Value ?? 0,
            parent: info["ParentWholeDisk"] as? String ?? identifier,
            media: info["MediaName"] as? String ?? ""
        )
    }

    /// Discos que ya monta ntfs-3g, leídos de la lista de procesos: "<ruta>/ntfs-3g /dev/diskXsY <punto> -o ...".
    static func ntfs3gMounts() -> [String: String] {
        let result = Shell.run("/bin/ps", ["-axo", "args="])
        guard result.status == 0, let text = String(data: result.output, encoding: .utf8) else { return [:] }

        var mounts: [String: String] = [:]
        for line in text.split(separator: "\n") {
            guard let marker = line.range(of: "/ntfs-3g /dev/") else { continue }
            let rest = line[marker.upperBound...]
            guard let space = rest.firstIndex(of: " ") else { continue }
            let device = String(rest[..<space])
            var mountPoint = String(rest[rest.index(after: space)...])
            if let options = mountPoint.range(of: " -o ") { mountPoint = String(mountPoint[..<options.lowerBound]) }
            mounts[device] = mountPoint
        }
        return mounts
    }

    private static func plist(_ data: Data) -> [String: Any]? {
        try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }
}
