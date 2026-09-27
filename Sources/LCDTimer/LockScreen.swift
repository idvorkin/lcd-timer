import AppKit
import SwiftUI
import TimerCore

/// Story 012: what covers every screen while locked. The LED time under LOCd with a line beneath, or, after
/// Escape, "Are you sure?" with a line and how to answer. Plain values, so `just snapshots` renders it too.
struct LockScreen: View {
    let face: Face
    let line: String
    let asking: Bool

    /// How much of the work underneath is hidden: enough that it cannot be read, not so much it disappears.
    static let dim = 0.88

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            VStack(spacing: size.height * 0.04) {
                if asking {
                    Text("Are you sure?")
                        .font(.system(size: size.height * 0.08, weight: .bold))
                        .foregroundStyle(Tone.amber.color)
                } else {
                    FaceLayout(face: face)
                        .frame(width: size.width * 0.7, height: size.height * 0.5)
                }
                Text(line)
                    .font(.system(size: size.height * (asking ? 0.045 : 0.032), weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: size.width * 0.7)
                Text(asking ? "Y  give up     any other key  keep going" : "Esc  I want out")
                    .font(.system(size: size.height * 0.018, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(width: size.width, height: size.height)
        }
        .background(Color(white: 0.1).opacity(Self.dim))
    }
}

/// The lock screen fed from the model, taking the keys.
struct LockScreenView: View {
    @Environment(TimerModel.self) private var model
    @FocusState private var focused: Bool

    var body: some View {
        let now = model.now
        let lockout = model.lockout ?? Lockout(at: now)
        LockScreen(face: Face(locked: model.countdown, at: now), line: lockout.line(at: now),
                   asking: lockout.isAsking(at: now))
            .focusable()
            .focusEffectDisabled()
            .focused($focused)
            .onAppear { focused = true }
            .onKeyPress(phases: .down) { press in
                model.handleLocked(press)
                return .handled
            }
            .ignoresSafeArea()
    }
}

/// One borderless window per screen above everything, full-screen apps included, plus the app kept in front with
/// the Dock, menu bar and ⌘Tab off. ⌥⌘Esc still works: this is a speed bump, not a jail.
@MainActor
final class LockWindows {
    private var windows: [NSWindow] = []

    func show(model: TimerModel) {
        guard windows.isEmpty else { return }
        for screen in NSScreen.screens {
            let window = KeyableWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: LockScreenView().environment(model))
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }
        NSApp.activate()
        NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, .disableHideApplication]
        (windows.first { $0.screen == NSScreen.main } ?? windows.first)?.makeKey()
    }

    func hide() {
        NSApp.presentationOptions = []
        for window in windows { window.orderOut(nil) }
        windows = []
    }
}

/// Borderless windows refuse key status by default, and the lock screen needs the keys.
private final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
