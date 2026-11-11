/// A key as the timer reads it (stories 004, 005, 012, 013): which of the few keys it names this is, what it typed,
/// and whether a modifier was held. The app turns SwiftUI's `KeyPress` into one and asks `KeyCommand` what it does,
/// so every key decision is tested on the host and the window only delivers keys.
public struct KeyInput: Equatable, Sendable {
    public enum Named: Equatable, Sendable {
        case `return`, space, escape
        /// Delete or forward delete.
        case delete
        /// Any other key; what it typed is in `characters`.
        case other
    }

    public var named: Named
    public var characters: String
    /// Any modifier, Shift included.
    public var hasModifiers: Bool

    public init(_ named: Named = .other, characters: String = "", hasModifiers: Bool = false) {
        self.named = named
        self.characters = characters
        self.hasModifiers = hasModifiers
    }
}

/// What a key does in the timer window.
public enum KeyCommand: Equatable, Sendable {
    case type(Int)
    case commit, toggle, reset, backspace, lockOut
    /// Story 013: ? shows the keys; with them showing, any key only puts them away.
    case showHelp, dismissHelp

    /// Nil when the key is not the timer's, so it goes on to the system: a digit or `l` with a modifier held (⌘1,
    /// Shift-L), or any other key. Return, Space, Escape and Delete are the timer's with or without a modifier.
    public init?(_ key: KeyInput, showingHelp: Bool) {
        if showingHelp {
            self = .dismissHelp
            return
        }
        if key.characters == "?" {
            self = .showHelp
            return
        }
        switch key.named {
        case .return: self = .commit
        case .space: self = .toggle
        case .escape: self = .reset
        case .delete: self = .backspace
        case .other:
            guard !key.hasModifiers else { return nil }
            if key.characters == "l" {
                self = .lockOut
                return
            }
            guard let digit = key.characters.first?.wholeNumberValue else { return nil }
            self = .type(digit)
        }
    }
}

extension Lockout.Key {
    /// A key on the lock screen: Escape asks, anything else is what it typed. ⌘ keys never get here: the app's key
    /// monitor turns them into `.command` before the menu sees them.
    public init(_ key: KeyInput) {
        self = key.named == .escape ? .escape : .other(key.characters)
    }
}
