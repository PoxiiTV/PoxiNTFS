// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PoxiNTFS",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "PoxiNTFS", path: "Sources/PoxiNTFS")
    ]
)
