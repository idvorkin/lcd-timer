import Foundation
import Testing
@testable import TimerCore

private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

// Story 012: lock me out for a set time, with "are you sure?" on the way out.

@Test func theLineChangesEveryMinute() {
    let lockout = Lockout(at: t0)
    #expect(lockout.line(at: t0) == Lockout.lines[0])
    #expect(lockout.line(at: t0 + 59) == Lockout.lines[0])
    #expect(lockout.line(at: t0 + 60) == Lockout.lines[1])
    #expect(lockout.line(at: t0 + 60 * Double(Lockout.lines.count)) == Lockout.lines[0])
}

@Test func askingShowsADifferentLineThanTheOneOnScreen() {
    var lockout = Lockout(at: t0)
    lockout.ask(at: t0 + 30)
    #expect(lockout.isAsking(at: t0 + 30))
    #expect(lockout.line(at: t0 + 30) == Lockout.lines[1])
    // The question's line stays put while it is read, even across a minute boundary.
    #expect(lockout.line(at: t0 + 65) == Lockout.lines[1])
}

@Test func keepingGoingDismissesTheQuestion() {
    var lockout = Lockout(at: t0)
    lockout.ask(at: t0)
    lockout.keepGoing()
    #expect(!lockout.isAsking(at: t0 + 1))
}

@Test func anUnansweredQuestionGoesAway() {
    var lockout = Lockout(at: t0)
    lockout.ask(at: t0)
    #expect(lockout.isAsking(at: t0 + Lockout.askTimeout - 1))
    #expect(!lockout.isAsking(at: t0 + Lockout.askTimeout))
}

@Test func theLockedFaceIsTheTimeUnderLOCd() {
    var countdown = Countdown(duration: 1500)
    countdown.start(at: t0)
    #expect(Face(locked: countdown, at: t0 + 1) == Face(time: "24:59", tone: .red, word: "LOCd", wordTone: .amber))
    for letter in "LOCd" {
        #expect(!segments(for: letter).isEmpty)
    }
}
