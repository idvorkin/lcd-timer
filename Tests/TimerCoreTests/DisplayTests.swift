import CoreGraphics
import Testing
@testable import TimerCore

// Story 001: seven-segment digits with ghosts.

@Test func eightLightsEverySegment() {
    #expect(segments(for: "8") == Set(Segment.allCases))
}

@Test func oneLightsOnlyTheRightBars() {
    #expect(segments(for: "1") == [.b, .c])
}

@Test func unknownCharactersAreBlank() {
    #expect(segments(for: "x").isEmpty)
}

@Test func everyDigitDrawsAllSevenBarsSoTheGhostsShow() {
    let pieces = LedGeometry.pieces(of: "1", height: 100)
    #expect(pieces.count == 7)
    #expect(pieces.filter(\.isLit).count == 2)
}

@Test func theColonIsTwoLitDots() {
    let dots = LedGeometry.pieces(of: ":", height: 100)
    #expect(dots.count == 2)
    for dot in dots {
        #expect(dot.isLit)
        #expect(dot.rect.width == dot.rect.height)
    }
}

@Test func barsStopShortOfTheCorners() {
    let top = LedGeometry.frame(of: .a, height: 100)
    let left = LedGeometry.frame(of: .f, height: 100)
    #expect(!top.intersects(left))
}

@Test func piecesStayInsideTheStringsWidth() {
    let text = "12:34"
    let width = LedGeometry.width(of: text, height: 100)
    for piece in LedGeometry.pieces(of: text, height: 100) {
        #expect(piece.rect.minX >= 0 && piece.rect.maxX <= width + 0.001)
        #expect(piece.rect.minY >= 0 && piece.rect.maxY <= 100.001)
    }
}

// Story 002: the digits fill the window.

/// The drawn width of a string, glow padding included, as the app lays it out.
private func drawnWidth(_ text: String, _ height: CGFloat) -> CGFloat {
    LedGeometry.width(of: text, height: height) + 2 * LedGeometry.bar * height
}

@Test func aWideWindowIsFilledAcross() {
    let size = CGSize(width: 600, height: 1000)
    let (time, _) = LedGeometry.faceHeights(time: "05:00", word: nil, in: size)
    #expect(drawnWidth("05:00", time) <= 540)
    #expect(drawnWidth("05:00", time + 1) > 540)
}

@Test func aShortWindowCapsTheHeight() {
    let (time, _) = LedGeometry.faceHeights(time: "05:00", word: nil, in: CGSize(width: 10_000, height: 200))
    #expect(time * (1 + 2 * LedGeometry.bar) <= 180)
}

@Test func theWordSitsAboveAtItsShareAndBothFit() {
    let size = CGSize(width: 800, height: 400)
    let (time, word) = LedGeometry.faceHeights(time: "04:50", word: "PAUSEd", in: size)
    let padded = 1 + 2 * LedGeometry.bar
    #expect(word <= time * LedGeometry.wordRatio)
    #expect(word >= time * LedGeometry.wordRatio - 1)
    #expect(time * padded + word * padded + time * LedGeometry.lineGap <= 360)
    #expect(drawnWidth("PAUSEd", word) <= 720)
}

@Test func growingTheWindowGrowsTheDigits() {
    let small = LedGeometry.faceHeights(time: "05:00", word: nil, in: CGSize(width: 300, height: 150)).time
    let large = LedGeometry.faceHeights(time: "05:00", word: nil, in: CGSize(width: 1200, height: 600)).time
    #expect(large > small * 3.5)
}

@Test func emptyTextHasNoHeight() {
    #expect(LedGeometry.faceHeights(time: "", word: nil, in: CGSize(width: 600, height: 100)).time == 0)
}
