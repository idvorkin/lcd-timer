import SwiftUI
import TimerCore

/// `LCDTimer --icon <dir>.iconset` draws the app icon at every size `iconutil` wants and exits; `just app` turns
/// the set into `AppIcon.icns`. Drawn from the same LED view as the face, so the icon is never a stale bitmap.
@MainActor
enum AppIcon {
    static func runIfAsked() {
        let arguments = CommandLine.arguments
        guard let flag = arguments.firstIndex(of: "--icon"), arguments.count > flag + 1 else { return }
        let directory = URL(fileURLWithPath: arguments[flag + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for points in [16, 32, 128, 256, 512] {
            for multiple in [1, 2] {
                let name = multiple == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
                Snapshots.write(Tile(), to: directory.appendingPathComponent(name),
                                scale: CGFloat(points * multiple) / Tile.canvas)
            }
        }
        exit(0)
    }

    /// Apple's macOS icon grid: an 824-point rounded square centred on a 1024-point canvas.
    struct Tile: View {
        static let canvas: CGFloat = 1024
        static let side: CGFloat = 824

        var body: some View {
            let digits: CGFloat = 300
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(Color.black)
                .overlay(LedView(text: "5:00", color: Tone.red.color, height: digits))
                .frame(width: Self.side, height: Self.side)
                .frame(width: Self.canvas, height: Self.canvas)
        }
    }
}
