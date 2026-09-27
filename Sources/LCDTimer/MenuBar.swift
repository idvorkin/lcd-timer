import SwiftUI
import TimerCore

/// Story 010: the time left in the menu bar, drawn as a small LED panel in the state's colour; idle, just an `8`.
struct MenuBarLabel: View {
    let model: TimerModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let face = model.face
        let (text, tone): (String, Tone) = model.phase == .idle ? ("8", .white) : (face.time, face.tone)
        Image(nsImage: Self.render(text: text, tone: tone))
            .renderingMode(.original)
            .onAppear { OpenWindowBox.shared.action = openWindow }
    }

    /// A black pill with the LED digits on it, so it reads on a light or a dark menu bar.
    @MainActor
    static func render(text: String, tone: Tone) -> NSImage {
        let height: CGFloat = 11
        let content = LedView(text: text, color: tone.color, height: height)
            .padding(.horizontal, 2)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 4))
            .frame(height: 18)
        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = false
        return image
    }
}

struct MenuBarMenu: View {
    @Environment(TimerModel.self) private var model

    var body: some View {
        switch model.phase {
        case .running: Button("Pause") { model.toggle() }
        case .paused: Button("Resume") { model.toggle() }
        case .idle, .done: Button("Start") { model.commit() }
        }
        Button("Reset") { model.reset() }
        Button("Lock Me Out") { model.lockOut() }
        Button("Show Timer") { OpenWindowBox.shared.open() }
        Divider()
        Button("Quit LCD Timer") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
