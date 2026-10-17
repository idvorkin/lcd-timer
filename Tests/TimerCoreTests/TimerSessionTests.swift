import Foundation
import Testing

@testable import TimerCore

/// The fake clock: every test walks `now` forward from here by hand, so nothing waits.
private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

private func typed(_ digits: Int..., into session: inout TimerSession) {
    for digit in digits { session.type(digit, at: t0) }
}

extension [TimerSession.Report] {
    /// Just the events, for the tests that only care what happened and in which order.
    fileprivate var events: [TimerSession.Event] { map(\.event) }
}

// Story 006: zero chimes once.

@Test func zeroChimesOnceAndOnlyOnce() {
    var session = TimerSession(duration: 60)
    #expect(session.commit(at: t0).events == [.started])
    #expect(session.tick(at: t0 + 59).isEmpty)
    #expect(session.tick(at: t0 + 60).events == [.done])
    #expect(session.tick(at: t0 + 61).isEmpty)
    #expect(session.tick(at: t0 + 3600).isEmpty)
}

@Test func aSecondCountdownChimesAgain() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    session.tick(at: t0 + 60)
    #expect(session.commit(at: t0 + 70).events == [.started])
    #expect(session.tick(at: t0 + 130).events == [.done])
}

@Test func aPauseHoldsOffTheChime() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.toggle(at: t0 + 30).events == [.toggled])
    #expect(session.tick(at: t0 + 120).isEmpty)
    #expect(session.toggle(at: t0 + 120).events == [.toggled])
    #expect(session.tick(at: t0 + 149).isEmpty)
    #expect(session.tick(at: t0 + 150).events == [.done])
}

// lcd-9pd: a key that lands after zero but before the next tick still gets the chime first.

@Test func returnAfterZeroBeforeTheTickChimesThenStarts() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.commit(at: t0 + 60.05).events == [.done, .started])
    // The restarted countdown chimes at its own zero, too.
    #expect(session.tick(at: t0 + 121).events == [.done])
}

@Test func spaceAfterZeroBeforeTheTickChimesThenStarts() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.toggle(at: t0 + 60.05).events == [.done, .started])
}

@Test func lockAfterZeroBeforeTheTickChimesThenLocks() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.lockOut(at: t0 + 60.05).events == [.done, .started, .locked])
}

@Test func aDigitAfterZeroBeforeTheTickChimesThenTypes() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.type(5, at: t0 + 60.05).events == [.done])
    #expect(session.entry.digits == [5])
}

@Test func escapeAfterZeroBeforeTheTickChimesThenResets() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.reset(at: t0 + 60.05).events == [.done, .reset])
}

@Test func theLockLiftsBeforeAKeyAfterZeroIsRead() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.pressLocked(.escape, at: t0 + 60.05).events == [.unlocked, .done])
    #expect(session.lockout == nil)
}

@Test func aResetBeforeZeroNeverChimes() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.reset(at: t0 + 10).events == [.reset])
    #expect(session.tick(at: t0 + 120).isEmpty)
}

// lcd-5qq: each report carries the countdown as it was when its event happened, for story 014's log.

@Test func anOverdueDoneReportsZeroNotTheKeysState() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    let restart = session.commit(at: t0 + 60.05)
    #expect(restart.first == TimerSession.Report(event: .done, phase: .done, remaining: 0))
    #expect(restart.last == TimerSession.Report(event: .started, phase: .running, remaining: 60))

    var escaped = TimerSession(duration: 60)
    escaped.commit(at: t0)
    let reset = escaped.reset(at: t0 + 60.05)
    #expect(reset.first == TimerSession.Report(event: .done, phase: .done, remaining: 0))
    #expect(reset.last == TimerSession.Report(event: .reset, phase: .idle, remaining: 60))
}

@Test func aLockAfterZeroKeepsTheDoneReportAtZero() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(
        session.lockOut(at: t0 + 60.05) == [
            TimerSession.Report(event: .done, phase: .done, remaining: 0),
            TimerSession.Report(event: .started, phase: .running, remaining: 60),
            TimerSession.Report(event: .locked, phase: .running, remaining: 60),
        ])
}

@Test func aPauseReportsTheTimeLeftAtThePause() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.toggle(at: t0 + 20) == [TimerSession.Report(event: .toggled, phase: .paused, remaining: 40)])
}

@Test func aShortCountdownReportsItsStartAndItsZero() {
    var session = TimerSession(duration: 3)
    #expect(session.commit(at: t0) == [TimerSession.Report(event: .started, phase: .running, remaining: 3)])
    #expect(session.tick(at: t0 + 3) == [TimerSession.Report(event: .done, phase: .done, remaining: 0)])
}

@Test func aGivenUpLockReportsTheTimeItWasGivenUpAt() {
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    session.pressLocked(.escape, at: t0 + 10)
    #expect(
        session.pressLocked(.other("y"), at: t0 + 12) == [
            TimerSession.Report(event: .abandoned, phase: .running, remaining: 48),
            TimerSession.Report(event: .reset, phase: .idle, remaining: 60),
            TimerSession.Report(event: .unlocked, phase: .idle, remaining: 60),
        ])
}

// Stories 004, 005: the keys' guards.

@Test func returnSetsWhatWasTypedAndStartsIt() {
    var session = TimerSession(duration: 300)
    typed(9, 0, into: &session)
    #expect(session.commit(at: t0).events == [.started])
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
    #expect(session.lockOut(at: t0).events == [.started, .locked])
    #expect(session.countdown.duration == 1500)
    #expect(session.lockout == Lockout(at: t0))
    #expect(session.tick(at: t0 + 1499).isEmpty)
    #expect(session.lockout != nil)
    #expect(session.tick(at: t0 + 1500).events == [.unlocked, .done])
    #expect(session.lockout == nil)
    #expect(session.tick(at: t0 + 1501).isEmpty)
}

@Test func lockingCarriesOnARunningCountdown() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(session.lockOut(at: t0 + 20).events == [.locked])
    #expect(session.countdown.end == t0 + 60)
    #expect(session.tick(at: t0 + 60).events == [.unlocked, .done])
}

@Test func lockingResumesAPausedCountdown() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    session.toggle(at: t0 + 20)
    #expect(session.lockOut(at: t0 + 100).events == [.toggled, .locked])
    #expect(session.tick(at: t0 + 140).events == [.unlocked, .done])
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
    #expect(session.pressLocked(.other("y"), at: t0 + 12).events == [.abandoned, .reset, .unlocked])
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
    #expect(session.tick(at: t0 + 60).events == [.unlocked, .done])
}

@Test func keysWithoutALockDoNothing() {
    var session = TimerSession(duration: 60)
    #expect(session.pressLocked(.other("y"), at: t0).isEmpty)
    #expect(session.phase(at: t0) == .idle)
}

// lcd-umw: the clock is watched only while it matters, and the screens change at most once a second.

@Test func onlyARunningCountdownOrALockNeedsTheClock() {
    var session = TimerSession(duration: 60)
    #expect(!session.needsClock(at: t0))
    session.commit(at: t0)
    #expect(session.needsClock(at: t0 + 1))
    session.toggle(at: t0 + 10)
    #expect(!session.needsClock(at: t0 + 3600))
    session.toggle(at: t0 + 3600)
    #expect(session.needsClock(at: t0 + 3601))
    #expect(!session.needsClock(at: t0 + 3650))

    var locked = TimerSession(duration: 60)
    locked.lockOut(at: t0)
    #expect(locked.needsClock(at: t0 + 30))
    locked.tick(at: t0 + 60)
    #expect(!locked.needsClock(at: t0 + 61))
}

@Test func theDisplayChangesOncePerSecondWhileRunningAndNeverWhileIdle() {
    var session = TimerSession(duration: 60)
    #expect(session.display(at: t0) == session.display(at: t0 + 3600))
    session.commit(at: t0)
    #expect(session.display(at: t0 + 0.1) == session.display(at: t0 + 0.9))
    #expect(session.display(at: t0 + 0.9) != session.display(at: t0 + 1.1))
    session.toggle(at: t0 + 10)
    #expect(session.display(at: t0 + 10) == session.display(at: t0 + 3600))
}

@Test func theLockScreenChangesWithItsLineAndItsQuestion() {
    var session = TimerSession(duration: 3600)
    session.lockOut(at: t0)
    let start = session.display(at: t0 + 0.5)
    #expect(start.lockedFace != nil && start.lockLine != nil && !start.asking)
    #expect(session.display(at: t0 + 59.5).lockLine != session.display(at: t0 + 60.5).lockLine)
    session.pressLocked(.escape, at: t0 + 100)
    #expect(session.display(at: t0 + 100.5).asking)
    #expect(!session.display(at: t0 + 100 + Lockout.askTimeout + 1).asking)
}

// lcd-umw, end to end on the fake clock: a 10 Hz ticker that runs only while `needsClock` says so, redrawing only
// when `display` changes, the way the app drives it. Oracle: story 007 (zero on time, about one redraw a second while
// counting down, nothing while idle or after zero) and story 012 (the lock lifts at zero, the question times out).

/// Ticks `session` every 0.1 s from `start` while it needs the clock, up to `limit`; returns the redraws (display
/// changes), every reported event with its time, and when the ticker stopped.
private func runTicker(
    _ session: inout TimerSession, from start: Date, limit: TimeInterval
) -> (redraws: Int, events: [(TimerSession.Event, TimeInterval)], stoppedAt: TimeInterval?) {
    var shown = session.display(at: start)
    var redraws = 0
    var events: [(TimerSession.Event, TimeInterval)] = []
    var step = 1
    while Double(step) * 0.1 <= limit {
        let time = start + Double(step) * 0.1
        events += session.tick(at: time).map { ($0.event, time.timeIntervalSince(start)) }
        let next = session.display(at: time)
        if next != shown {
            shown = next
            redraws += 1
        }
        if !session.needsClock(at: time) { return (redraws, events, time.timeIntervalSince(start)) }
        step += 1
    }
    return (redraws, events, nil)
}

@Test func aThreeSecondCountdownOnTheGatedTickerIsDoneOnTimeThenGoesQuiet() {
    var session = TimerSession(duration: 3)
    session.commit(at: t0)
    let run = runTicker(&session, from: t0, limit: 3600)
    #expect(run.events.map(\.0) == [.done])
    #expect(abs((run.events.first?.1 ?? -1) - 3) < 0.11)
    #expect(run.stoppedAt != nil && run.stoppedAt! < 3.11)
    #expect((3...4).contains(run.redraws))
    // Done stays done: an hour later nothing has changed and nothing asks for the clock.
    let done = session.display(at: t0 + 3.2)
    #expect(session.display(at: t0 + 3600) == done)
    #expect(!session.needsClock(at: t0 + 3600))
    #expect(session.tick(at: t0 + 3600).isEmpty)
}

@Test func aPausedCountdownStopsTheTickerAndResumingStartsIt() {
    var session = TimerSession(duration: 60)
    session.commit(at: t0)
    #expect(runTicker(&session, from: t0, limit: 5).stoppedAt == nil)
    session.toggle(at: t0 + 5)
    #expect(!session.needsClock(at: t0 + 5))
    let paused = session.display(at: t0 + 5)
    #expect(session.display(at: t0 + 1800) == paused)
    session.toggle(at: t0 + 1800)
    #expect(session.needsClock(at: t0 + 1800))
    let rest = runTicker(&session, from: t0 + 1800, limit: 3600)
    #expect(rest.events.map(\.0) == [.done])
    #expect(abs((rest.events.first?.1 ?? -1) - 55) < 0.11)
    #expect((55...56).contains(rest.redraws))
}

@Test func aLockedCountdownOnTheGatedTickerShowsItsLineAndQuestionThenLifts() {
    var session = TimerSession(duration: 130)
    session.lockOut(at: t0)
    let firstLine = session.display(at: t0).lockLine
    #expect(firstLine != nil)
    #expect(runTicker(&session, from: t0, limit: 61).stoppedAt == nil)
    #expect(session.display(at: t0 + 61).lockLine != firstLine)
    session.pressLocked(.escape, at: t0 + 70)
    #expect(session.display(at: t0 + 70.1).asking)
    #expect(session.needsClock(at: t0 + 70.1))
    #expect(!session.display(at: t0 + 70 + Lockout.askTimeout + 0.1).asking)
    let rest = runTicker(&session, from: t0 + 70, limit: 3600)
    #expect(rest.events.map(\.0) == [.unlocked, .done])
    #expect(abs((rest.events.first?.1 ?? -1) - 60) < 0.11)
    #expect(session.lockout == nil)
    #expect(!session.needsClock(at: t0 + 3600))
}
