import Foundation

/// Story 012: the screen is locked while the countdown runs. Leaving early is one question away: Escape asks
/// "are you sure?" with a line to think about, Y gives up, anything else goes back to work. An unanswered question
/// goes away by itself after `askTimeout`. Every call takes `now`, so the host tests drive it with an injected clock.
public struct Lockout: Equatable, Sendable {
    /// How often the line under the time changes while locked.
    public static let lineEvery: TimeInterval = 60
    /// How long "are you sure?" waits for an answer before going back to the lock.
    public static let askTimeout: TimeInterval = 20

    public private(set) var since: Date
    /// When "are you sure?" was asked; nil when it is not showing.
    public private(set) var askedAt: Date?

    public init(at now: Date) {
        since = now
    }

    public func isAsking(at now: Date) -> Bool {
        guard let askedAt else { return false }
        return now < askedAt.addingTimeInterval(Self.askTimeout)
    }

    /// Escape.
    public mutating func ask(at now: Date) {
        askedAt = now
    }

    /// Any key but Y while asking.
    public mutating func keepGoing() {
        askedAt = nil
    }

    /// A key on the lock screen, as far as the lock cares.
    public enum Key: Equatable, Sendable {
        case escape
        /// Any ⌘ combination. ⌘Q, ⌘W and the other menu key equivalents would otherwise reach the app's menu and
        /// end the lock in one keystroke, so they count as Escape.
        case command
        case other(String)
    }

    /// A key while locked: Escape or a ⌘ key asks "are you sure?"; asked, Y gives up and anything else keeps
    /// going. Returns true when the answer is to give up.
    public mutating func press(_ key: Key, at now: Date) -> Bool {
        if isAsking(at: now) {
            if case .other(let characters) = key, characters.lowercased() == "y" { return true }
            keepGoing()
        } else if key == .escape || key == .command {
            ask(at: now)
        }
        return false
    }

    /// The line on screen: one per `lineEvery` while locked, and while asking the next one, so the question
    /// never repeats the line already read.
    public func line(at now: Date) -> String {
        let minutes = Int(now.timeIntervalSince(since) / Self.lineEvery)
        let index = isAsking(at: now) ? Int((askedAt ?? now).timeIntervalSince(since) / Self.lineEvery) + 1 : minutes
        return Self.lines[index % Self.lines.count]
    }

    /// Eulogy virtues over résumé virtues: what the minutes are for.
    public static let lines = [
        "Nobody's eulogy says they answered email quickly.",
        "What will they say about you? Earn it in the next few minutes.",
        "The résumé virtues can wait. The eulogy virtues are built right now.",
        "You won't remember the scroll. You'll remember who you became.",
        "Future you is watching. Make them proud.",
        "Be the person your eulogy describes.",
        "Discipline is choosing what you want most over what you want now.",
        "This is the block you promised yourself.",
        "One promise kept to yourself is worth ten made.",
        "Nobody at your funeral will mention the tab you almost opened.",
    ]
}

extension Face {
    /// The locked screen's LED: the time left in red under an amber LOCd.
    public init(locked countdown: Countdown, at now: Date) {
        self.init(time: clockText(countdown.remaining(at: now)), tone: .red, word: "LOCd", wordTone: .amber)
    }
}
