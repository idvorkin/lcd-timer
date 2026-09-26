import Foundation

/// A countdown that stores when it ends, not how many ticks it has had: the time left is always derived from the
/// clock, so sleep, a hidden window or a busy Mac never make it drift (story 007). Every call takes `now`, so the
/// host tests drive it with an injected clock.
public struct Countdown: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case running(end: Date)
        case paused(remaining: TimeInterval)
    }

    public enum Phase: Equatable, Sendable {
        case idle, running, paused, done
    }

    /// The time the countdown was set to, in whole seconds.
    public private(set) var duration: TimeInterval
    public private(set) var state: State = .idle

    public init(duration: TimeInterval) {
        self.duration = duration
    }

    public func phase(at now: Date) -> Phase {
        switch state {
        case .idle: .idle
        case .paused: .paused
        case .running(let end): now >= end ? .done : .running
        }
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle: duration
        case .paused(let remaining): remaining
        case .running(let end): max(0, end.timeIntervalSince(now))
        }
    }

    /// When a running countdown reaches zero; nil when it is not running.
    public var end: Date? {
        if case .running(let end) = state { end } else { nil }
    }

    /// Space and a click: start when idle or done, pause when running, resume when paused.
    public mutating func toggle(at now: Date) {
        switch phase(at: now) {
        case .idle, .done: start(at: now)
        case .running: state = .paused(remaining: remaining(at: now))
        case .paused: state = .running(end: now.addingTimeInterval(remaining(at: now)))
        }
    }

    public mutating func start(at now: Date) {
        guard duration > 0 else { return }
        state = .running(end: now.addingTimeInterval(duration))
    }

    /// Escape: back to the time it was set to, idle.
    public mutating func reset() {
        state = .idle
    }

    /// A new time, idle.
    public mutating func set(duration: TimeInterval) {
        self.duration = duration
        state = .idle
    }
}

/// `MM:SS`, counting a started second as a whole one so 4:59.2 reads `05:00` and zero is only shown at zero.
public func clockText(_ seconds: TimeInterval) -> String {
    let whole = Int(seconds.rounded(.up))
    return String(format: "%02d:%02d", whole / 60, whole % 60)
}
