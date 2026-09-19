// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NodeHUD",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NodeHUD", targets: ["NodeHUD"])
    ],
    targets: [
        .executableTarget(name: "NodeHUD", path: "Sources")
    ]
)
