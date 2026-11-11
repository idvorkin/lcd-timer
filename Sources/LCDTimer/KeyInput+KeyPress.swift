import SwiftUI
import TimerCore

extension KeyInput {
    /// SwiftUI's key press as TimerCore reads keys. The only key logic left in the app: naming the keys.
    init(_ press: KeyPress) {
        let named: Named
        switch press.key {
        case .return: named = .return
        case .space: named = .space
        case .escape: named = .escape
        case .delete, .deleteForward: named = .delete
        default: named = .other
        }
        self.init(named, characters: press.characters, hasModifiers: !press.modifiers.isEmpty)
    }
}
