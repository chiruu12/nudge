// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NudgeWidget",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NudgeWidget",
            path: "Sources"
        ),
    ]
)
