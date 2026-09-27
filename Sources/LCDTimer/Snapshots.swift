import AppKit
import SwiftUI
import TimerCore

/// `LCDTimer --snapshots <dir>` renders each face and the menu bar pill to PNG and exits, so the look is checked
/// without screen-recording permission (`just snapshots`).
@MainActor
enum Snapshots {
    static func runIfAsked() {
        let arguments = CommandLine.arguments
        guard let flag = arguments.firstIndex(of: "--snapshots"), arguments.count > flag + 1 else { return }
        let directory = URL(fileURLWithPath: arguments[flag + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let faces: [(String, Face)] = [
            ("idle", Face(time: "05:00", tone: .white)),
            ("running", Face(time: "04:59", tone: .red)),
            ("paused", Face(time: "04:50", tone: .red, word: "PAUSEd", wordTone: .amber)),
            ("done", Face(time: "donE", tone: .red)),
        ]
        let sizes = [CGSize(width: 480, height: 200), CGSize(width: 300, height: 300)]
        for (name, face) in faces {
            for size in sizes {
                write(FaceLayout(face: face).background(Color.black).frame(width: size.width, height: size.height),
                      to: directory.appendingPathComponent("\(name)-\(Int(size.width))x\(Int(size.height)).png"))
            }
        }
        // The windowed panel over something busy, to judge how much shows through.
        let busy = LinearGradient(colors: [.white, .blue, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        write(FaceLayout(face: faces[1].1)
                .background(Color.black.opacity(TimerFaceView.windowedOpacity))
                .frame(width: 480, height: 200)
                .background(busy),
              to: directory.appendingPathComponent("running-over-content.png"))
        // Story 012: the lock screen over something busy, locked and asking.
        let t0 = Date()
        var countdown = Countdown(duration: 1500)
        countdown.start(at: t0)
        for (name, asking) in [("locked", false), ("lock-asking", true)] {
            write(LockScreen(face: Face(locked: countdown, at: t0 + 1), line: Lockout.lines[asking ? 1 : 0], asking: asking)
                    .frame(width: 1440, height: 900)
                    .background(busy),
                  to: directory.appendingPathComponent("\(name).png"), scale: 1)
        }
        for (name, text, tone) in [("menubar-idle", "8", Tone.white), ("menubar-running", "04:59", .red)] {
            let image = MenuBarLabel.render(text: text, tone: tone)
            write(Image(nsImage: image).padding(4).background(Color.gray), to: directory.appendingPathComponent("\(name).png"))
        }
        exit(0)
    }

    static func write(_ view: some View, to url: URL, scale: CGFloat = 2) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.cgImage else { return }
        let bitmap = NSBitmapImageRep(cgImage: image)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    }
}
