// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LCDTimer",
    platforms: [.macOS(.v14)],
    dependencies: [
        // The session log and crash capture (story 014). Pinned to a tag: the train's bug-kit release.
        .package(url: "https://github.com/idvorkin/bug-kit.git", exact: "0.3.2")
    ],
    targets: [
        // Platform-free: glyphs, geometry, the countdown and the typed entry. Tested on the host.
        .target(name: "TimerCore"),
        .testTarget(name: "TimerCoreTests", dependencies: ["TimerCore"]),
        // The SwiftUI app. `just app` wraps the binary into LCDTimer.app.
        .executableTarget(
            name: "LCDTimer", dependencies: ["TimerCore", .product(name: "BugKit", package: "bug-kit")]),
    ]
)
