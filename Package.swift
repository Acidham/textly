// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Textly",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Textly",
            path: "Sources/Textly"
        ),
    ]
)
