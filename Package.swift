// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LCDTimer",
    platforms: [.macOS(.v14)],
    targets: [
        // Platform-free: glyphs, geometry, the countdown and the typed entry. Tested on the host.
        .target(name: "TimerCore"),
        .testTarget(name: "TimerCoreTests", dependencies: ["TimerCore"]),
        // The SwiftUI app. `just app` wraps the binary into LCDTimer.app.
        .executableTarget(name: "LCDTimer", dependencies: ["TimerCore"]),
    ]
)
