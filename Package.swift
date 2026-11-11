// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuietLine",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "QuietLine", targets: ["QuietLine"])],
    targets: [
        .target(name: "QuietLineCore"),
        .executableTarget(name: "QuietLine", dependencies: ["QuietLineCore"]),
        .testTarget(name: "QuietLineCoreTests", dependencies: ["QuietLineCore"])
    ]
)
