import AppKit
import Observation
import SwiftUI
import TimerCore
import UserNotifications
import os

private let log = Logger(subsystem: "com.idvorkin.lcdtimer", category: "timer")

/// The one timer on the Mac: the rules live in `TimerSession` (TimerCore); this feeds it keys and the clock and acts
/// on what it reports (sound, notification, lock windows, log), and owns the window it shows in. The countdown derives
/// its time from the clock (story 007); the tick only moves `now` so the views redraw, and notices zero.
@MainActor @Observable
final class TimerModel {
    private(set) var session: TimerSession
    private(set) var now: Date
    /// Story 013: the list of keys over the face.
    var showingHelp = false

    /// Story 008: on top of every window and on every Space, only the LED panel.
    var pinned: Bool {
        didSet {
            UserDefaults.standard.set(pinned, forKey: Keys.pinned)
            applyPin()
        }
    }

    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let notifications = Notifications()
    @ObservationIgnored private let lockWindows = LockWindows()

    private enum Keys {
        static let duration = "lastDuration"
        static let pinned = "pinned"
    }

    /// `clock` is the only source of the time: every rule is asked with what it returns.
    init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
        now = clock()
        let saved = UserDefaults.standard.double(forKey: Keys.duration)
        session = TimerSession(duration: saved > 0 ? saved : 300)
        // Pinned until I unpin it: only a pinned window can show over a full-screen app's Space.
        pinned = UserDefaults.standard.object(forKey: Keys.pinned) as? Bool ?? true
        notifications.onOpen = { OpenWindowBox.shared.open() }
        notifications.requestPermission()
        startTicking()
    }

    var countdown: Countdown { session.countdown }
    /// Story 012: set while the screen is locked for the countdown.
    var lockout: Lockout? { session.lockout }
    var face: Face { Face(countdown: countdown, entry: session.entry, at: now) }
    var phase: Countdown.Phase { countdown.phase(at: now) }

    // MARK: - keys (stories 004, 005)

    func handle(_ press: KeyPress) -> Bool {
        // Story 013: ? shows the keys; any key puts them away without doing anything else.
        if showingHelp {
            showingHelp = false
            return true
        }
        if press.characters == "?" {
            showingHelp = true
            return true
        }
        switch press.key {
        case .return: commit()
        case .space: toggle()
        case .escape: reset()
        case .delete, .deleteForward: session.backspace()
        case _ where press.characters == "l" && press.modifiers.isEmpty: lockOut()
        default:
            guard let digit = press.characters.first?.wholeNumberValue, press.modifiers.isEmpty else { return false }
            type(digit)
        }
        return true
    }

    // The actions: each asks the session with a fresh `now`, then acts on what it reports.

    func type(_ digit: Int) { act { $0.type(digit, at: $1) } }

    func commit() { act { $0.commit(at: $1) } }
    func toggle() { act { $0.toggle(at: $1) } }
    func reset() { act { $0.reset(at: $1) } }
    func lockOut() { act { $0.lockOut(at: $1) } }

    func handleLocked(_ key: Lockout.Key) {
        if key == .command && lockout != nil { log.info("lock ⌘ key") }
        act { $0.pressLocked(key, at: $1) }
    }

    private func act(_ rule: (inout TimerSession, Date) -> [TimerSession.Report]) {
        now = clock()
        perform(rule(&session, now))
    }

    /// The Mac's side of each event (stories 006, 012).
    private func perform(_ reports: [TimerSession.Report]) {
        for report in reports {
            // Story 014: the same events, in this launch's JSONL session log, each with the state it happened in.
            BugLog.session.event(
                "\(report.event)", ["phase": .string("\(report.phase)"), "remaining": .double(report.remaining)])
            switch report.event {
            case .started:
                UserDefaults.standard.set(countdown.duration, forKey: Keys.duration)
                log.info("start \(self.countdown.duration, privacy: .public)s")
                scheduleNotification()
            case .toggled:
                log.info("toggle -> \(String(describing: self.countdown.state), privacy: .public)")
                scheduleNotification()
            case .reset:
                log.info("reset")
                scheduleNotification()
            case .locked:
                log.info("lock \(self.countdown.remaining(at: self.now), privacy: .public)s")
                lockWindows.show(model: self)
            case .abandoned:
                log.info("lock abandoned")
            case .unlocked:
                lockWindows.hide()
                log.info("unlock")
            case .done:
                log.info("done")
                NSSound(named: "Glass")?.play()
            }
        }
    }

    // MARK: - the clock (stories 006, 007)

    private func startTicking() {
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                log.info("wake")
                self?.tick()
            }
        }
    }

    private func tick() { act { $0.tick(at: $1) } }

    /// The notification is scheduled for the end when a countdown starts or resumes, so it fires on time even with
    /// the app asleep; pausing or resetting withdraws it.
    private func scheduleNotification() {
        if let end = countdown.end {
            notifications.schedule(in: end.timeIntervalSince(now))
        } else {
            notifications.cancel()
        }
    }

    // MARK: - the window (stories 008, 009)

    /// Observed so the panel turns solid black in full screen and translucent again as a window.
    private(set) var isFullScreen = false

    func attach(_ window: NSWindow) {
        guard window !== self.window else { return }
        self.window = window
        window.setFrameAutosaveName("LCDTimerWindow")
        window.isMovableByWindowBackground = true
        // Clear, so the view's translucent black panel is the only background (story 008).
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        isFullScreen = window.styleMask.contains(.fullScreen)
        let center = NotificationCenter.default
        center.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.isFullScreen = true
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
        center.addObserver(forName: NSWindow.didExitFullScreenNotification, object: window, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.isFullScreen = false
                self?.applyPin()
            }
        }
        applyPin()
    }

    /// ⌃⌘F. A pinned window is on every Space, which full screen does not allow, so it becomes an ordinary
    /// full-screen window for the duration and is pinned again on the way out.
    func toggleFullScreen() {
        guard let window else { return }
        if !isFullScreen {
            window.level = .normal
            window.collectionBehavior = [.fullScreenPrimary]
        }
        window.toggleFullScreen(nil)
    }

    private func applyPin() {
        guard let window, !isFullScreen else { return }
        window.level = pinned ? .floating : .normal
        window.collectionBehavior = pinned ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.fullScreenPrimary]
        log.info(
            "window pinned=\(self.pinned, privacy: .public) onActiveSpace=\(window.isOnActiveSpace, privacy: .public) visible=\(window.isVisible, privacy: .public) level=\(window.level.rawValue, privacy: .public) frame=\(NSStringFromRect(window.frame), privacy: .public)"
        )
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = pinned
        }
    }
}

/// Story 006: the macOS notification at zero. Notifications need a bundle, so under `swift run` they are off.
private final class Notifications: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private static let id = "countdown-done"
    var onOpen: @MainActor () -> Void = {}

    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil ? nil : .current()
    }

    func requestPermission() {
        guard let center else { return }
        center.delegate = self
        center.requestAuthorization(options: [.alert]) { granted, error in
            log.info(
                "notifications granted=\(granted, privacy: .public) \(error?.localizedDescription ?? "", privacy: .public)"
            )
        }
    }

    func schedule(in seconds: TimeInterval) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.body = "Your countdown reached zero."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: Self.id, content: content, trigger: trigger))
    }

    func cancel() {
        center?.removePendingNotificationRequests(withIdentifiers: [Self.id])
    }

    // Shown even while the app is in front; the chime is the app's own, so no sound here.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { onOpen() }
    }
}
