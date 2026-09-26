import SwiftUI
import TimerCore

@main
struct LCDTimerApp: App {
    // Not `@State`: in the macOS 27 SDK that is a macro whose plugin ships only with Xcode, and this builds with
    // the Command Line Tools. The App is made once and the model is @Observable, so a plain property is enough.
    private let model: TimerModel

    init() {
        Snapshots.runIfAsked()  // before the model, which asks for notification permission
        model = TimerModel()
        // The app's own ⌃⌘F replaces AppKit's automatic "Enter Full Screen" item (see TimerModel.toggleFullScreen).
        UserDefaults.standard.set(false, forKey: "NSFullScreenMenuItemEverywhere")
    }

    var body: some Scene {
        Window("LCD Timer", id: "timer") {
            TimerFaceView()
                .environment(model)
                .frame(minWidth: 160, minHeight: 80)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 200)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .printItem) {
                Button(model.pinned ? "Unpin" : "Pin on Top") { model.pinned.toggle() }
                    .keyboardShortcut("p")
            }
            CommandGroup(before: .windowArrangement) {
                Button("Toggle Full Screen") { model.toggleFullScreen() }
                    .keyboardShortcut("f", modifiers: [.control, .command])
            }
        }

        MenuBarExtra {
            MenuBarMenu()
                .environment(model)
        } label: {
            MenuBarLabel(model: model)
        }
    }
}

/// Opens the timer window, or brings it forward, from outside a view: the menu bar and the notification.
/// `openWindow` lives in the SwiftUI environment, so the always-present menu bar label captures it here.
@MainActor
final class OpenWindowBox {
    static let shared = OpenWindowBox()
    var action: OpenWindowAction?

    func open() {
        action?(id: "timer")
        NSApp.activate()
    }
}
