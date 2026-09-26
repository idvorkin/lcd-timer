import SwiftUI
import TimerCore

/// A seven-segment LED string, drawn — no font (story 001). Lit bars glow; unlit bars are faint ghosts, so
/// every digit has an `8` behind it and the display reads as one panel.
struct LedView: View {
    let text: String
    let color: Color
    let height: CGFloat
    var ghosts = true

    static let ghost = Color(red: 0x24 / 255, green: 0x24 / 255, blue: 0x24 / 255)

    /// Room around the digits for the glow, which would otherwise be clipped at the edges.
    static func glowPadding(height: CGFloat) -> CGFloat { LedGeometry.bar * height }

    var body: some View {
        let pad = Self.glowPadding(height: height)
        let width = LedGeometry.width(of: text, height: height)
        Canvas { context, _ in
            let radius = LedGeometry.bar * height / 2
            let pieces = LedGeometry.pieces(of: text, height: height)
            context.translateBy(x: pad, y: pad)
            if ghosts {
                for piece in pieces where !piece.isLit {
                    context.fill(Path(roundedRect: piece.rect, cornerRadius: radius), with: .color(Self.ghost))
                }
            }
            var glow = context
            glow.addFilter(.shadow(color: color.opacity(0.85), radius: LedGeometry.bar * height * 0.7))
            for piece in pieces where piece.isLit {
                glow.fill(Path(roundedRect: piece.rect, cornerRadius: radius), with: .color(color))
            }
        }
        .frame(width: width + 2 * pad, height: height + 2 * pad)
        .accessibilityLabel(text)
    }
}

extension Tone {
    /// The Gym Timer's palette.
    var color: Color {
        switch self {
        case .red: Color(red: 0xff / 255, green: 0x3b / 255, blue: 0x30 / 255)
        case .green: Color(red: 0x34 / 255, green: 0xc7 / 255, blue: 0x59 / 255)
        case .amber: Color(red: 0xff / 255, green: 0xcc / 255, blue: 0x00 / 255)
        case .white: Color(red: 0xe6 / 255, green: 0xe6 / 255, blue: 0xe6 / 255)
        }
    }
}
