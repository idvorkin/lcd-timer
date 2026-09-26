/// Seven-segment glyphs, ported from context-grabber's `lib/gym/sevenSegment.ts`.
///
/// Segments are named the classic way:
///
///      a
///    f   b
///      g
///    e   c
///      d
///
/// Letters are the seven-segment spellings a gym clock would use (PAUSEd, donE); anything not in the table is
/// blank. `:` and `.` are not glyphs — the display draws them as dots — but they are recognised so a caller can
/// lay a string out.
public enum Segment: CaseIterable, Sendable {
    case a, b, c, d, e, f, g
}

private let lit: [Character: String] = [
    "0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg",
    "5": "acdfg", "6": "acdefg", "7": "abc", "8": "abcdefg", "9": "abcdfg",
    "A": "abcefg", "b": "cdefg", "C": "adef", "c": "deg", "d": "bcdeg",
    "E": "adefg", "F": "aefg", "G": "acdef", "H": "bcefg", "h": "cefg",
    "I": "bc", "J": "bcd", "L": "def", "n": "ceg", "O": "abcdef",
    "o": "cdeg", "P": "abefg", "r": "eg", "S": "acdfg", "t": "defg",
    "U": "bcdef", "u": "cde", "Y": "bcdfg", "-": "g", " ": "",
]

private let glyphs: [Character: Set<Segment>] = lit.mapValues { spelling in
    Set(spelling.map { letter in
        switch letter {
        case "a": .a
        case "b": .b
        case "c": .c
        case "d": .d
        case "e": .e
        case "f": .f
        default: .g
        }
    })
}

/// The lit segments for one character; blank for anything the display cannot spell.
public func segments(for character: Character) -> Set<Segment> {
    glyphs[character] ?? []
}

/// True for the characters drawn as dots between digits rather than as segments.
public func isSeparator(_ character: Character) -> Bool {
    character == ":" || character == "."
}
