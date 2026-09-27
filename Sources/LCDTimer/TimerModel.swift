import AppKit
import Observation
import os
import SwiftUI
import TimerCore
import UserNotifications

private let log = Logger(subsystem: "com.idvorkin.lcdtimer", category: "timer")

/// The one timer: its countdown, what is being typed, and the window it shows in. The countdown derives its time
/// from the clock (story 007); the tick only moves `now` so the views redraw, and notices zero.
@MainActor @Observable
final class TimerModel {
    private(set) var countdown: Countdown
    private(set) var entry = Entry()
    private(set) var now = Date()
    /// Story 012: set while the screen is locked for the countdown.
    private(set) var lockout: Lockout?
    /// Story 013: the list of keys over the face.
    var showingHelp = false

    /// Story 008: on top of every window and on every Space, only the LED panel.
    var pinned: Bool {
        didSet {
            UserDefaults.standard.set(pinned, forKey: Keys.pinned)
            applyPin()
        }
    }

    @ObservationIgnored private weak var window: NSWindow?
    @ObservationIgnored private var announcedDone = false
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let notifications = Notifications()
    @ObservationIgnored private let lockWindows = LockWindows()

    private enum Keys {
        static let duration = "lastDuration"
        static let pinned = "pinned"
    }

    init() {
        let saved = UserDefaults.standard.double(forKey: Keys.duration)
        countdown = Countdown(duration: saved > 0 ? saved : 300)
        // Pinned until I unpin it: only a pinned window can show over a full-screen app's Space.
        pinned = UserDefaults.standard.object(forKey: Keys.pinned) as? Bool ?? true
        notifications.onOpen = { OpenWindowBox.shared.open() }
        notifications.requestPermission()
        startTicking()
    }

    var face: Face { Face(countdown: countdown, entry: entry, at: now) }
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
        case .delete, .deleteForward: entry.backspace()
        case _ where press.characters == "l" && press.modifiers.isEmpty: lockOut()
        default:
            guard let digit = press.characters.first?.wholeNumberValue, press.modifiers.isEmpty else { return false }
            type(digit)
        }
        return true
    }

    /// A digit starts or extends the typed time; it is ignored while a countdown is running or paused.
    func type(_ digit: Int) {
        if phase == .done { countdown.reset() }
        guard phase == .idle else { return }
        entry.type(digit)
    }

    /// Return: set what was typed and start it; with nothing typed, start the last time again.
    func commit() {
        guard phase == .idle || phase == .done else { return }
        if !entry.isEmpty {
            countdown.set(duration: entry.duration)
            UserDefaults.standard.set(entry.duration, forKey: Keys.duration)
            entry.clear()
        }
        start()
    }

    /// Space and a click: start, pause or resume. Something typed is set first, as Return would.
    func toggle() {
        guard lockout == nil else { return }  // pausing would hold the lock forever
        if !entry.isEmpty { return commit() }
        switch phase {
        case .idle, .done: start()
        case .running, .paused:
            countdown.toggle(at: Date())
            log.info("toggle -> \(String(describing: self.countdown.state), privacy: .public)")
            scheduleNotification()
            tick()
        }
    }

    /// Escape: forget what was typed and go back to the set time, idle.
    func reset() {
        entry.clear()
        countdown.reset()
        log.info("reset")
        scheduleNotification()
        tick()
    }

    // MARK: - the lockout (story 012)

    /// L: start what was typed (or the last time, or carry on a running one) with the screen locked until zero.
    func lockOut() {
        guard lockout == nil else { return }
        switch phase {
        case .paused: toggle()
        case .idle, .done: commit()
        case .running: break
        }
        guard phase == .running else { return }
        lockout = Lockout(at: Date())
        log.info("lock \(self.countdown.remaining(at: Date()), privacy: .public)s")
        lockWindows.show(model: self)
    }

    /// Keys on the lock screen: Escape asks "are you sure?"; asked, Y gives up and anything else keeps going.
    func handleLocked(_ press: KeyPress) {
        guard var lockout else { return }
        let now = Date()
        if lockout.isAsking(at: now) {
            if press.characters.lowercased() == "y" {
                log.info("lock abandoned")
                return reset()
            }
            lockout.keepGoing()
        } else if press.key == .escape {
            lockout.ask(at: now)
        }
        self.lockout = lockout
    }

    private func unlock() {
        lockout = nil
        lockWindows.hide()
        log.info("unlock")
    }

    private func start() {
        countdown.start(at: Date())
        announcedDone = false
        log.info("start \(self.countdown.duration, privacy: .public)s")
        scheduleNotification()
        tick()
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

    private func tick() {
        now = Date()
        if lockout != nil && phase != .running { unlock() }
        if phase == .done && !announcedDone {
            announcedDone = true
            log.info("done")
            NSSound(named: "Glass")?.play()
        }
    }

    /// The notification is scheduled for the end when a countdown starts or resumes, so it fires on time even with
    /// the app asleep; pausing or resetting withdraws it.
    private func scheduleNotification() {
        if let end = countdown.end {
            notifications.schedule(at: end)
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
        center.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isFullScreen = true
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
        center.addObserver(forName: NSWindow.didExitFullScreenNotification, object: window, queue: .main) { [weak self] _ in
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
        log.info("window pinned=\(self.pinned, privacy: .public) onActiveSpace=\(window.isOnActiveSpace, privacy: .public) visible=\(window.isVisible, privacy: .public) level=\(window.level.rawValue, privacy: .public) frame=\(NSStringFromRect(window.frame), privacy: .public)")
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
            log.info("notifications granted=\(granted, privacy: .public) \(error?.localizedDescription ?? "", privacy: .public)")
        }
    }

    func schedule(at end: Date) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.body = "Your countdown reached zero."
        let seconds = max(1, end.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
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
