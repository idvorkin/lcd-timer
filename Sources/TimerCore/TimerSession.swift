import Foundation

/// The timer's rules without the Mac around them: the countdown, what is being typed, the lockout (story 012) and
/// the chime at zero (story 006). The app feeds it keys and the clock, then acts on the `Report`s it returns: the
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

    /// An event with the countdown as it was when the event happened, not after the whole action: a key after zero
    /// reports the overdue `.done` at zero, then its own events (lcd-5qq).
    public struct Report: Equatable, Sendable {
        public let event: Event
        public let phase: Countdown.Phase
        public let remaining: TimeInterval
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

    /// Everything the window, the menu bar and the lock screen show at `now`. The app redraws only when this
    /// changes, about once a second while counting down and never while idle, paused or done (lcd-umw).
    public struct Display: Equatable, Sendable {
        public let face: Face
        public let lockedFace: Face?
        public let lockLine: String?
        public let asking: Bool
    }

    public func display(at now: Date) -> Display {
        Display(
            face: Face(countdown: countdown, entry: entry, at: now),
            lockedFace: lockout.map { _ in Face(locked: countdown, at: now) },
            lockLine: lockout?.line(at: now),
            asking: lockout?.isAsking(at: now) ?? false)
    }

    /// Whether the clock needs watching: only a running countdown (and the lock over it) changes with time, so the
    /// app ticks only then (lcd-umw).
    public func needsClock(at now: Date) -> Bool {
        phase(at: now) == .running || lockout != nil
    }

    // Every action settles the clock first (`tick`): a key that lands after zero but before the app's next tick
    // still gets the chime and lifts the lock before the key does anything (lcd-9pd). A second `tick` at the same
    // moment reports nothing, so actions that call other actions never announce twice.

    /// A digit starts or extends the typed time; it is ignored while a countdown is running or paused.
    @discardableResult
    public mutating func type(_ digit: Int, at now: Date) -> [Report] {
        let overdue = tick(at: now)
        if phase(at: now) == .done { countdown.reset() }
        guard phase(at: now) == .idle else { return overdue }
        entry.type(digit)
        return overdue
    }

    public mutating func backspace() {
        entry.backspace()
    }

    /// Return: set what was typed and start it; with nothing typed, start the last time again.
    @discardableResult
    public mutating func commit(at now: Date) -> [Report] {
        let overdue = tick(at: now)
        guard phase(at: now) == .idle || phase(at: now) == .done else { return overdue }
        if !entry.isEmpty {
            countdown.set(duration: entry.duration)
            entry.clear()
        }
        return overdue + start(at: now)
    }

    /// Space and a click: start, pause or resume. Something typed is set first, as Return would.
    @discardableResult
    public mutating func toggle(at now: Date) -> [Report] {
        let overdue = tick(at: now)
        guard lockout == nil else { return overdue }  // pausing would hold the lock forever
        if !entry.isEmpty { return overdue + commit(at: now) }
        switch phase(at: now) {
        case .idle, .done: return overdue + start(at: now)
        case .running, .paused:
            countdown.toggle(at: now)
            return overdue + [report(.toggled, at: now)] + tick(at: now)
        }
    }

    /// Escape: forget what was typed and go back to the set time, idle.
    @discardableResult
    public mutating func reset(at now: Date) -> [Report] {
        let overdue = tick(at: now)
        entry.clear()
        countdown.reset()
        return overdue + [report(.reset, at: now)] + tick(at: now)
    }

    /// L: start what was typed (or the last time, or carry on a running one) with the screen locked until zero.
    @discardableResult
    public mutating func lockOut(at now: Date) -> [Report] {
        var reports = tick(at: now)
        guard lockout == nil else { return reports }
        switch phase(at: now) {
        case .paused: reports += toggle(at: now)
        case .idle, .done: reports += commit(at: now)
        case .running: break
        }
        guard phase(at: now) == .running else { return reports }
        lockout = Lockout(at: now)
        return reports + [report(.locked, at: now)]
    }

    /// Keys on the lock screen: Escape or a ⌘ key asks "are you sure?"; asked, Y gives up and anything else keeps
    /// going (`Lockout.press`).
    @discardableResult
    public mutating func pressLocked(_ key: Lockout.Key, at now: Date) -> [Report] {
        let overdue = tick(at: now)
        guard var lockout else { return overdue }
        if lockout.press(key, at: now) { return [report(.abandoned, at: now)] + reset(at: now) }
        self.lockout = lockout
        return []
    }

    /// The clock moved: the lock lifts once the countdown is no longer running, and zero chimes once.
    @discardableResult
    public mutating func tick(at now: Date) -> [Report] {
        var reports: [Report] = []
        if lockout != nil && phase(at: now) != .running {
            lockout = nil
            reports.append(report(.unlocked, at: now))
        }
        if phase(at: now) == .done && !announcedDone {
            announcedDone = true
            reports.append(report(.done, at: now))
        }
        return reports
    }

    private mutating func start(at now: Date) -> [Report] {
        countdown.start(at: now)
        announcedDone = false
        return [report(.started, at: now)] + tick(at: now)
    }

    private func report(_ event: Event, at now: Date) -> Report {
        Report(event: event, phase: phase(at: now), remaining: countdown.remaining(at: now))
    }
}
