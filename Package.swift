// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OpenITermCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "OpenITermCore", targets: ["OpenITermCore"])
    ],
    targets: [
        .target(name: "OpenITermCore", path: "OpenITerm/Core"),
        .testTarget(name: "OpenITermCoreTests", dependencies: ["OpenITermCore"])
    ]
)
