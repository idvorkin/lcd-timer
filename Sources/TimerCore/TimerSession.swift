import Foundation

/// The timer's rules without the Mac around them: the countdown, what is being typed, the lockout (story 012) and
/// the chime at zero (story 006). The app feeds it keys and the clock, then acts on the `Event`s it returns: the
/// sound, the notification, the lock windows, the log. Every call takes `now`, so the host tests walk a fake clock
/// through it.
public struct TimerSession: Equatable, Sendable {
    /// What happened, for the app to act on, in order.
    public enum Event: Equatable, Sendable {
        /// A countdown started from its set time.
        case started
        /// Paused or resumed.
        case toggled
        /// Back to the set time, idle.
        case reset
        /// The screen locked.
        case locked
        /// Y on "are you sure?": the lock is given up; `.reset` and `.unlocked` follow.
        case abandoned
        /// The lock lifted, at zero or given up.
        case unlocked
        /// Zero, once per countdown: the chime.
        case done
    }

    public private(set) var countdown: Countdown
    public private(set) var entry = Entry()
    /// Set while the screen is locked for the countdown.
    public private(set) var lockout: Lockout?
    private var announcedDone = false

    public init(duration: TimeInterval) {
        countdown = Countdown(duration: duration)
    }

    public func phase(at now: Date) -> Countdown.Phase {
        countdown.phase(at: now)
    }

    /// A digit starts or extends the typed time; it is ignored while a countdown is running or paused.
    public mutating func type(_ digit: Int, at now: Date) {
        if phase(at: now) == .done { countdown.reset() }
        guard phase(at: now) == .idle else { return }
        entry.type(digit)
    }

    public mutating func backspace() {
        entry.backspace()
    }

    /// Return: set what was typed and start it; with nothing typed, start the last time again.
    @discardableResult
    public mutating func commit(at now: Date) -> [Event] {
        guard phase(at: now) == .idle || phase(at: now) == .done else { return [] }
        if !entry.isEmpty {
            countdown.set(duration: entry.duration)
            entry.clear()
        }
        return start(at: now)
    }

    /// Space and a click: start, pause or resume. Something typed is set first, as Return would.
    @discardableResult
    public mutating func toggle(at now: Date) -> [Event] {
        guard lockout == nil else { return [] }  // pausing would hold the lock forever
        if !entry.isEmpty { return commit(at: now) }
        switch phase(at: now) {
        case .idle, .done: return start(at: now)
        case .running, .paused:
            countdown.toggle(at: now)
            return [.toggled] + tick(at: now)
        }
    }

    /// Escape: forget what was typed and go back to the set time, idle.
    @discardableResult
    public mutating func reset(at now: Date) -> [Event] {
        entry.clear()
        countdown.reset()
        return [.reset] + tick(at: now)
    }

    /// L: start what was typed (or the last time, or carry on a running one) with the screen locked until zero.
    @discardableResult
    public mutating func lockOut(at now: Date) -> [Event] {
        guard lockout == nil else { return [] }
        var events: [Event] = []
        switch phase(at: now) {
        case .paused: events = toggle(at: now)
        case .idle, .done: events = commit(at: now)
        case .running: break
        }
        guard phase(at: now) == .running else { return events }
        lockout = Lockout(at: now)
        return events + [.locked]
    }

    /// Keys on the lock screen: Escape or a ⌘ key asks "are you sure?"; asked, Y gives up and anything else keeps
    /// going (`Lockout.press`).
    @discardableResult
    public mutating func pressLocked(_ key: Lockout.Key, at now: Date) -> [Event] {
        guard var lockout else { return [] }
        if lockout.press(key, at: now) { return [.abandoned] + reset(at: now) }
        self.lockout = lockout
        return []
    }

    /// The clock moved: the lock lifts once the countdown is no longer running, and zero chimes once.
    @discardableResult
    public mutating func tick(at now: Date) -> [Event] {
        var events: [Event] = []
        if lockout != nil && phase(at: now) != .running {
            lockout = nil
            events.append(.unlocked)
        }
        if phase(at: now) == .done && !announcedDone {
            announcedDone = true
            events.append(.done)
        }
        return events
    }

    private mutating func start(at now: Date) -> [Event] {
        countdown.start(at: now)
        announcedDone = false
        return [.started] + tick(at: now)
    }
}
