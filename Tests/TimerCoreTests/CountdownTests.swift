import Foundation
import Testing
@testable import TimerCore

private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

// Story 003: the colour and an LED word say what the timer is doing.

@Test func goingThroughACountdownChangesTheFace() {
    var countdown = Countdown(duration: 300)
    let entry = Entry()
    #expect(Face(countdown: countdown, entry: entry, at: t0) == Face(time: "05:00", tone: .white))

    countdown.toggle(at: t0)
    #expect(Face(countdown: countdown, entry: entry, at: t0 + 1) == Face(time: "04:59", tone: .red))

    countdown.toggle(at: t0 + 10)
    #expect(Face(countdown: countdown, entry: entry, at: t0 + 60)
        == Face(time: "04:50", tone: .red, word: "PAUSEd", wordTone: .amber))

    countdown.toggle(at: t0 + 60)
    #expect(Face(countdown: countdown, entry: entry, at: t0 + 60 + 290) == Face(time: "donE", tone: .red))
}

@Test func theLedWordsAreSpellable() {
    for word in ["PAUSEd", "donE"] {
        for letter in word {
            #expect(!segments(for: letter).isEmpty, "\(letter) in \(word)")
        }
    }
}

// Story 004: type a time like a microwave.

@Test func typingFillsFromTheRight() {
    var entry = Entry()
    entry.type(5)
    #expect(entry.text == "00:05")
    entry.type(0)
    #expect(entry.text == "00:50")
    entry.type(0)
    #expect(entry.text == "05:00")
    #expect(entry.duration == 300)
}

@Test func secondsPast59CarryIntoMinutes() {
    var entry = Entry()
    entry.type(9)
    entry.type(0)
    #expect(entry.duration == 90)
    #expect(clockText(entry.duration) == "01:30")
}

@Test func backspaceRemovesTheLastDigit() {
    var entry = Entry()
    entry.type(1)
    entry.type(2)
    entry.backspace()
    #expect(entry.text == "00:01")
}

@Test func entryStopsAtFourDigitsAndIgnoresLeadingZeros() {
    var entry = Entry()
    entry.type(0)
    #expect(entry.isEmpty)
    for digit in [1, 2, 3, 4, 5] { entry.type(digit) }
    #expect(entry.text == "12:34")
}

@Test func typingShowsOnTheIdleFace() {
    var entry = Entry()
    entry.type(7)
    #expect(Face(countdown: Countdown(duration: 300), entry: entry, at: t0) == Face(time: "00:07", tone: .white))
}

// Story 005: start, pause, resume and reset.

@Test func pauseAndResumeKeepTheTime() {
    var countdown = Countdown(duration: 60)
    countdown.toggle(at: t0)
    countdown.toggle(at: t0 + 20)
    #expect(countdown.phase(at: t0 + 500) == .paused)
    #expect(countdown.remaining(at: t0 + 500) == 40)
    countdown.toggle(at: t0 + 500)
    #expect(countdown.remaining(at: t0 + 510) == 30)
}

@Test func resetGoesBackToTheSetTime() {
    var countdown = Countdown(duration: 60)
    countdown.toggle(at: t0)
    countdown.reset()
    #expect(countdown.phase(at: t0 + 30) == .idle)
    #expect(countdown.remaining(at: t0 + 30) == 60)
}

@Test func aZeroTimeDoesNotStart() {
    var countdown = Countdown(duration: 0)
    countdown.toggle(at: t0)
    #expect(countdown.phase(at: t0) == .idle)
}

@Test func toggleWhenDoneStartsAgain() {
    var countdown = Countdown(duration: 10)
    countdown.toggle(at: t0)
    #expect(countdown.phase(at: t0 + 10) == .done)
    countdown.toggle(at: t0 + 20)
    #expect(countdown.remaining(at: t0 + 21) == 9)
}

// Story 007: the time stays right through sleep.

@Test func timeLeftComesFromTheClockNotTicks() {
    var countdown = Countdown(duration: 600)
    countdown.toggle(at: t0)
    // Six minutes left, then the lid is shut for two: nothing ticked in between.
    #expect(countdown.remaining(at: t0 + 240) == 360)
    #expect(clockText(countdown.remaining(at: t0 + 360)) == "04:00")
}

@Test func runningOutWhileAsleepReadsDone() {
    var countdown = Countdown(duration: 60)
    countdown.toggle(at: t0)
    #expect(countdown.phase(at: t0 + 3600) == .done)
    #expect(countdown.remaining(at: t0 + 3600) == 0)
}

@Test func aStartedSecondCountsAsWhole() {
    #expect(clockText(299.2) == "05:00")
    #expect(clockText(0.4) == "00:01")
    #expect(clockText(0) == "00:00")
}
