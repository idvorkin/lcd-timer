import Foundation

/// The LED palette: what a gym clock is. Green is kept for rest, once rounds exist.
public enum Tone: Equatable, Sendable {
    case white, red, amber, green
}

/// What the display shows (story 003): the main LED line, its colour, and an optional LED word above it.
public struct Face: Equatable, Sendable {
    public var time: String
    public var tone: Tone
    public var word: String?
    public var wordTone: Tone?

    public init(time: String, tone: Tone, word: String? = nil, wordTone: Tone? = nil) {
        self.time = time
        self.tone = tone
        self.word = word
        self.wordTone = wordTone
    }

    /// White while idle or typing, red while running, red under an amber PAUSEd while paused, red donE at zero.
    public init(countdown: Countdown, entry: Entry, at now: Date) {
        switch countdown.phase(at: now) {
        case .idle:
            self.init(time: entry.isEmpty ? clockText(countdown.duration) : entry.text, tone: .white)
        case .running:
            self.init(time: clockText(countdown.remaining(at: now)), tone: .red)
        case .paused:
            self.init(time: clockText(countdown.remaining(at: now)), tone: .red, word: "PAUSEd", wordTone: .amber)
        case .done:
            self.init(time: "donE", tone: .red)
        }
    }
}
