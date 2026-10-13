import Foundation
import Testing

@testable import TimerCore

/// The fake clock: every test walks `now` forward from here by hand, so nothing waits.
private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

private func typed(_ digits: Int..., into session: inout TimerSession) {
    for digit in digits { session.type(digit, at: t0) }
}

// Story 006: zero chimes once.

@Test func zeroChimesOnceAndOnlyOnce() {
    var session = TimerSession(duration: 60)
    #expect(session.commit(at: t0) == [.started])
    #expect(session.tick(at: t0 + 59).isEmpty)
    #expect(session.tick(at: t0 + 60) == [.done])
    #expect(session.tick(at: t0 + 61).isEmpty)
    #expect(session.tick(at: t0 + 3600).isEmpty)
}

@Test func aSecondCountdownChimesAgain() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    session.tick(at: t0 + 60)
    #expect(session.commit(at: t0 + 70) == [.started])
    #expect(session.tick(at: t0 + 130) == [.done])
}

@Test func aPauseHoldsOffTheChime() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.toggle(at: t0 + 30) == [.toggled])
    #expect(session.tick(at: t0 + 120).isEmpty)
    #expect(session.toggle(at: t0 + 120) == [.toggled])
    #expect(session.tick(at: t0 + 149).isEmpty)
    #expect(session.tick(at: t0 + 150) == [.done])
}

// lcd-9pd: a key that lands after zero but before the next tick still gets the chime first.

@Test func returnAfterZeroBeforeTheTickChimesThenStarts() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.commit(at: t0 + 60.05) == [.done, .started])
    // The restarted countdown chimes at its own zero, too.
    #expect(session.tick(at: t0 + 121) == [.done])
}

@Test func spaceAfterZeroBeforeTheTickChimesThenStarts() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.toggle(at: t0 + 60.05) == [.done, .started])
}

@Test func lockAfterZeroBeforeTheTickChimesThenLocks() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.lockOut(at: t0 + 60.05) == [.done, .started, .locked])
}

@Test func aDigitAfterZeroBeforeTheTickChimesThenTypes() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.type(5, at: t0 + 60.05) == [.done])
    #expect(session.entry.digits == [5])
}

@Test func escapeAfterZeroBeforeTheTickChimesThenResets() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.reset(at: t0 + 60.05) == [.done, .reset])
}

@Test func theLockLiftsBeforeAKeyAfterZeroIsRead() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.pressLocked(.escape, at: t0 + 60.05) == [.unlocked, .done])
    #expect(session.lockout == nil)
}

@Test func aResetBeforeZeroNeverChimes() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.reset(at: t0 + 10) == [.reset])
    #expect(session.tick(at: t0 + 120).isEmpty)
}

// Stories 004, 005: the keys' guards.

@Test func returnSetsWhatWasTypedAndStartsIt() {
    var session = TimerSession(duration: 300)
    typed(9, 0, into: &session)
    #expect(session.commit(at: t0) == [.started])
    #expect(session.countdown.duration == 90)
    #expect(session.entry.isEmpty)
}

@Test func digitsAreIgnoredWhileRunningAndStartOverAfterZero() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    session.type(5, at: t0 + 10)
    #expect(session.entry.isEmpty)
    session.type(5, at: t0 + 60)
    #expect(session.phase(at: t0 + 60) == .idle)
    #expect(session.entry.digits == [5])
}

@Test func returnDoesNothingWhileRunning() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.commit(at: t0 + 10).isEmpty)
    #expect(session.countdown.end == t0 + 60)
}

// Story 012: the lock lifts at zero, and only then (or on Y).

@Test func lockingRunsToZeroThenLifts() {
    var session = TimerSession(duration: 300)
    typed(2, 5, 0, 0, into: &session)
    #expect(session.lockOut(at: t0) == [.started, .locked])
    #expect(session.countdown.duration == 1500)
    #expect(session.lockout == Lockout(at: t0))
    #expect(session.tick(at: t0 + 1499).isEmpty)
    #expect(session.lockout != nil)
    #expect(session.tick(at: t0 + 1500) == [.unlocked, .done])
    #expect(session.lockout == nil)
    #expect(session.tick(at: t0 + 1501).isEmpty)
}

@Test func lockingCarriesOnARunningCountdown() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.lockOut(at: t0 + 20) == [.locked])
    #expect(session.countdown.end == t0 + 60)
    #expect(session.tick(at: t0 + 60) == [.unlocked, .done])
}

@Test func lockingResumesAPausedCountdown() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    session.toggle(at: t0 + 20)
    #expect(session.lockOut(at: t0 + 100) == [.toggled, .locked])
    #expect(session.tick(at: t0 + 140) == [.unlocked, .done])
}

@Test func spaceCannotPauseTheLock() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.toggle(at: t0 + 10).isEmpty)
    #expect(session.phase(at: t0 + 10) == .running)
}

@Test func lockingTwiceDoesNotRestartTheLock() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.lockOut(at: t0 + 10).isEmpty)
    #expect(session.lockout == Lockout(at: t0))
}

@Test func yGivesUpResetsAndLifts() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.pressLocked(.escape, at: t0 + 10).isEmpty)
    #expect(session.lockout?.isAsking(at: t0 + 10) == true)
    #expect(session.pressLocked(.other("y"), at: t0 + 12) == [.abandoned, .reset, .unlocked])
    #expect(session.lockout == nil)
    #expect(session.phase(at: t0 + 12) == .idle)
    // Given up, zero never comes.
    #expect(session.tick(at: t0 + 60).isEmpty)
}

@Test func anyOtherKeyKeepsTheLock() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    session.pressLocked(.command, at: t0 + 10)
    #expect(session.pressLocked(.other("n"), at: t0 + 11).isEmpty)
    #expect(session.lockout?.isAsking(at: t0 + 11) == false)
    #expect(session.phase(at: t0 + 11) == .running)
    #expect(session.tick(at: t0 + 60) == [.unlocked, .done])
}

@Test func keysWithoutALockDoNothing() {
    var session = TimerSession(duration: 60)
    #expect(session.pressLocked(.other("y"), at: t0).isEmpty)
    #expect(session.phase(at: t0) == .idle)
}
