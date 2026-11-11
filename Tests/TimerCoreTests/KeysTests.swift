import Foundation
import Testing

@testable import TimerCore

private func command(_ key: KeyInput, showingHelp: Bool = false) -> KeyCommand? {
    KeyCommand(key, showingHelp: showingHelp)
}

private func typed(_ characters: String, modifiers: Bool = false) -> KeyInput {
    KeyInput(characters: characters, hasModifiers: modifiers)
}

// Story 004: digits type a time, Delete takes one back, Return starts it.

@Test func digitsTypeATime() {
    #expect(command(typed("5")) == .type(5))
    #expect(command(typed("0")) == .type(0))
    #expect(command(typed("9")) == .type(9))
}

@Test func returnStartsAndDeleteTakesADigitBack() {
    #expect(command(KeyInput(.return, characters: "\r")) == .commit)
    #expect(command(KeyInput(.delete)) == .backspace)
}

// Story 005: Space starts, pauses and resumes; Escape resets.

@Test func spaceTogglesAndEscapeResets() {
    #expect(command(KeyInput(.space, characters: " ")) == .toggle)
    #expect(command(KeyInput(.escape)) == .reset)
}

@Test func theNamedKeysWorkWithAModifierHeld() {
    #expect(command(KeyInput(.space, characters: " ", hasModifiers: true)) == .toggle)
    #expect(command(KeyInput(.return, characters: "\r", hasModifiers: true)) == .commit)
    #expect(command(KeyInput(.escape, hasModifiers: true)) == .reset)
    #expect(command(KeyInput(.delete, hasModifiers: true)) == .backspace)
}

// Story 012: L locks.

@Test func lLocks() {
    #expect(command(typed("l")) == .lockOut)
}

@Test func aModifiedDigitOrLGoesToTheSystem() {
    #expect(command(typed("1", modifiers: true)) == nil)  // ⌘1
    #expect(command(typed("L", modifiers: true)) == nil)  // Shift-L
    #expect(command(typed("l", modifiers: true)) == nil)  // ⌃L
}

@Test func otherKeysGoToTheSystem() {
    #expect(command(typed("x")) == nil)
    #expect(command(typed("")) == nil)
}

// Story 013: ? shows the keys, and the next key only puts them away.

@Test func questionMarkShowsTheKeys() {
    #expect(command(typed("?", modifiers: true)) == .showHelp)  // Shift-/
    #expect(command(typed("?")) == .showHelp)
}

@Test func withTheKeysShowingAnyKeyOnlyPutsThemAway() {
    for key in [
        typed("5"), typed("l"), typed("x"), typed("?"), typed("1", modifiers: true),
        KeyInput(.return), KeyInput(.space, characters: " "), KeyInput(.escape), KeyInput(.delete),
    ] {
        #expect(command(key, showingHelp: true) == .dismissHelp)
    }
}

// Story 012: on the lock screen Escape asks; Y gives up; anything else is what it typed.

@Test func lockScreenKeys() {
    #expect(Lockout.Key(KeyInput(.escape)) == .escape)
    #expect(Lockout.Key(typed("y")) == .other("y"))
    #expect(Lockout.Key(KeyInput(.space, characters: " ")) == .other(" "))
    #expect(Lockout.Key(KeyInput(.return, characters: "\r")) == .other("\r"))
}

@Test func escapeThenYOnTheLockScreenGivesUp() {
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
    var session = TimerSession(duration: 60)
    session.lockOut(at: t0)
    #expect(session.pressLocked(Lockout.Key(KeyInput(.escape)), at: t0 + 1).isEmpty)
    #expect(session.pressLocked(Lockout.Key(typed("y")), at: t0 + 2).map(\.event) == [.abandoned, .reset, .unlocked])
    #expect(session.lockout == nil)
}
