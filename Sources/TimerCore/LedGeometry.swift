import CoreGraphics

/// Where the bars and dots of an LED string sit, ported from context-grabber's `components/LedDisplay.tsx`.
///
/// Everything is sized from the height: a digit is 0.55 × height wide, a bar 0.11 × height thick, digits are
/// 0.13 × height apart and a separator is 0.18 × height wide. Bars stop short of the corners so they read as
/// separate LEDs.
public enum LedGeometry {
    public static let digitWidth: CGFloat = 0.55
    public static let bar: CGFloat = 0.11
    public static let gap: CGFloat = 0.13
    public static let separatorWidth: CGFloat = 0.18

    /// One piece of the display: a segment or a separator dot, with whether it is lit.
    public struct Piece: Equatable, Sendable {
        public var rect: CGRect
        public var isLit: Bool
    }

    /// The width of `text` drawn `height` tall.
    public static func width(of text: String, height: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let glyphs = text.reduce(CGFloat(0)) { $0 + charWidth($1) * height }
        return glyphs + CGFloat(text.count - 1) * gap * height
    }

    /// The word's height as a share of the time's.
    public static let wordRatio: CGFloat = 0.45
    /// The space between the word and the time, as a share of the time's height.
    public static let lineGap: CGFloat = 0.08

    /// The heights that make a face fill `size` (story 002): the time as tall as fits, the word above it at
    /// `wordRatio` of that, both inside `fill` of the width and height. Each string is drawn with glow padding of
    /// one bar on every side, so that padding counts too.
    public static func faceHeights(time: String, word: String?, in size: CGSize, fill: CGFloat = 0.9)
        -> (time: CGFloat, word: CGFloat)
    {
        let padding = 2 * bar
        let timeWidth = width(of: time, height: 1) + padding
        guard timeWidth > padding else { return (0, 0) }
        var stack = 1 + padding
        if word != nil { stack += wordRatio * (1 + padding) + lineGap }
        let timeHeight = max(0, min(size.width * fill / timeWidth, size.height * fill / stack).rounded(.down))
        guard let word else { return (timeHeight, 0) }
        let wordFits = size.width * fill / (width(of: word, height: 1) + padding)
        return (timeHeight, min(timeHeight * wordRatio, wordFits).rounded(.down))
    }

    /// Every bar and dot of `text` drawn `height` tall with its top-left at the origin. Unlit segments are
    /// included (the ghosts); separators only have lit dots.
    public static func pieces(of text: String, height h: CGFloat) -> [Piece] {
        var pieces: [Piece] = []
        var x: CGFloat = 0
        for character in text {
            if isSeparator(character) {
                let t = bar * h
                let left = x + (separatorWidth * h - t) / 2
                let tops = character == ":" ? [h * 0.3 - t / 2, h * 0.7 - t / 2] : [h - t]
                for top in tops {
                    pieces.append(Piece(rect: CGRect(x: left, y: top, width: t, height: t), isLit: true))
                }
            } else {
                let on = segments(for: character)
                for segment in Segment.allCases {
                    pieces.append(Piece(rect: frame(of: segment, height: h).offsetBy(dx: x, dy: 0), isLit: on.contains(segment)))
                }
            }
            x += (charWidth(character) + gap) * h
        }
        return pieces
    }

    /// Where one segment sits inside a digit `h` tall.
    static func frame(of segment: Segment, height h: CGFloat) -> CGRect {
        let w = digitWidth * h
        let t = bar * h
        let inset = t * 0.55
        let horizontalWidth = w - 2 * inset
        let verticalHeight = h / 2 - inset - t / 2
        switch segment {
        case .a: return CGRect(x: inset, y: 0, width: horizontalWidth, height: t)
        case .g: return CGRect(x: inset, y: (h - t) / 2, width: horizontalWidth, height: t)
        case .d: return CGRect(x: inset, y: h - t, width: horizontalWidth, height: t)
        case .f: return CGRect(x: 0, y: inset + t / 2, width: t, height: verticalHeight)
        case .b: return CGRect(x: w - t, y: inset + t / 2, width: t, height: verticalHeight)
        case .e: return CGRect(x: 0, y: h / 2 + t / 2, width: t, height: verticalHeight)
        case .c: return CGRect(x: w - t, y: h / 2 + t / 2, width: t, height: verticalHeight)
        }
    }

    private static func charWidth(_ character: Character) -> CGFloat {
        isSeparator(character) ? separatorWidth : digitWidth
    }
}
