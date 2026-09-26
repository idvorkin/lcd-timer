import Foundation

/// A time typed like a microwave (story 004): digits fill from the right, `5` `0` `0` reads `05:00`.
public struct Entry: Equatable, Sendable {
    public static let maxDigits = 4

    public private(set) var digits: [Int] = []

    public init() {}

    public var isEmpty: Bool { digits.isEmpty }

    public mutating func type(_ digit: Int) {
        guard (0...9).contains(digit), digits.count < Self.maxDigits else { return }
        if digits.isEmpty && digit == 0 { return }  // a leading zero changes nothing on the display
        digits.append(digit)
    }

    public mutating func backspace() {
        _ = digits.popLast()
    }

    public mutating func clear() {
        digits = []
    }

    /// What the display shows while typing: the raw digits as `MM:SS`, not yet normalised.
    public var text: String {
        let padded = Array(repeating: 0, count: Self.maxDigits - digits.count) + digits
        return "\(padded[0])\(padded[1]):\(padded[2])\(padded[3])"
    }

    /// The typed time in seconds; seconds past 59 carry into minutes, so `90` is 1:30.
    public var duration: TimeInterval {
        let value = digits.reduce(0) { $0 * 10 + $1 }
        return TimeInterval((value / 100) * 60 + value % 100)
    }
}
