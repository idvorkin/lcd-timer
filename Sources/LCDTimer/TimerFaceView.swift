import SwiftUI
import TimerCore

/// The timer window's content: the LED word over the LED time, as big as the window allows (story 002), with the
/// keyboard driving everything (stories 004, 005) and a click doing what Space does.
struct TimerFaceView: View {
    @Environment(TimerModel.self) private var model
    @FocusState private var focused: Bool

    /// How opaque the black panel is as a window, so what is underneath still shows a little (story 008).
    /// Full screen is solid black: there it is the wall clock (story 009).
    static let windowedOpacity = 0.75

    var body: some View {
        FaceLayout(face: model.face)
            .background(Color.black.opacity(model.isFullScreen ? 1 : Self.windowedOpacity))
        .contentShape(Rectangle())
        .onTapGesture { model.toggle() }
        .overlay {
            if model.showingHelp {
                KeysHelp()
                    .background(Color.black)
                    .onTapGesture { model.showingHelp = false }
            }
        }
        .overlay(alignment: .topTrailing) { CornerButtons() }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(phases: .down) { press in model.handle(press) ? .handled : .ignored }
        .background(WindowAccessor { model.attach($0) })
        .ignoresSafeArea()
    }
}

/// Small and dim in the corner, so the digits stay the face: the keys (story 013), the pin (story 008) and the
/// lock (story 012).
struct CornerButtons: View {
    @Environment(TimerModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            corner("questionmark", help: "Keys (?)") { model.showingHelp.toggle() }
            corner(model.pinned ? "pin.fill" : "pin", help: model.pinned ? "Unpin (⌘P)" : "Pin on top (⌘P)") {
                model.pinned.toggle()
            }
            corner("lock.fill", help: "Lock me out until zero (L)") { model.lockOut() }
        }
        .padding(6)
    }

    private func corner(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.4))
        .help(help)
    }
}

/// Story 013: every key, over the face. Plain values, so `just snapshots` renders it.
struct KeysHelp: View {
    static let bindings: [(key: String, action: String)] = [
        ("0–9", "type a time"),
        ("Return", "start it (again)"),
        ("Space", "pause / resume"),
        ("Esc", "reset"),
        ("⌫", "delete a digit"),
        ("L", "lock me out until zero"),
        ("⌘P", "pin on top"),
        ("⌃⌘F", "full screen"),
        ("?", "these keys"),
    ]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 3) {
            ForEach(Self.bindings, id: \.key) { binding in
                GridRow {
                    Text(binding.key)
                        .foregroundStyle(Tone.amber.color)
                        .gridColumnAlignment(.trailing)
                    Text(binding.action)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .font(.system(size: 13, design: .monospaced))
        .minimumScaleFactor(0.5)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The LED word over the LED time, filling whatever space it is given.
struct FaceLayout: View {
    let face: Face

    var body: some View {
        GeometryReader { geometry in
            let (timeHeight, wordHeight) = LedGeometry.faceHeights(time: face.time, word: face.word, in: geometry.size)
            VStack(spacing: timeHeight * LedGeometry.lineGap) {
                if let word = face.word, let tone = face.wordTone {
                    LedView(text: word, color: tone.color, height: wordHeight)
                }
                LedView(text: face.time, color: face.tone.color, height: timeHeight)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// Hands the view's `NSWindow` to the model, which owns pinning and full screen.
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window { onWindow(window) }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
