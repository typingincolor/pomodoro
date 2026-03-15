import SwiftUI

struct SevenSegmentDigit: View {
    let digit: Int
    let color: Color
    let scale: CGFloat

    static let segmentMap: [[Bool]] = [
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    private var segments: [Bool] {
        let clamped = min(max(digit, 0), 9)
        return Self.segmentMap[clamped]
    }

    private let segmentLength: CGFloat = 20
    private let segmentThickness: CGFloat = 4
    private let digitWidth: CGFloat = 24
    private let digitHeight: CGFloat = 44

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let t = segmentThickness * scale
            let inset = t / 2

            let segmentDefs: [(CGPoint, Bool)] = [
                (CGPoint(x: inset, y: 0), true),                          // a - top
                (CGPoint(x: w - t, y: inset), false),                     // b - top right
                (CGPoint(x: w - t, y: h / 2 + inset), false),            // c - bottom right
                (CGPoint(x: inset, y: h - t), true),                      // d - bottom
                (CGPoint(x: 0, y: h / 2 + inset), false),                // e - bottom left
                (CGPoint(x: 0, y: inset), false),                         // f - top left
                (CGPoint(x: inset, y: (h - t) / 2), true),               // g - middle
            ]

            for (i, (origin, isHorizontal)) in segmentDefs.enumerated() {
                let segSize: CGSize = isHorizontal
                    ? CGSize(width: w - 2 * inset, height: t)
                    : CGSize(width: t, height: h / 2 - inset)
                let rect = CGRect(origin: origin, size: segSize)
                let path = RoundedRectangle(cornerRadius: t / 3)
                    .path(in: rect)

                let isOn = segments[i]
                let opacity: Double = isOn ? 1.0 : 0.05
                let segColor = color.opacity(opacity)
                context.fill(path, with: .color(segColor))

                if isOn {
                    context.fill(path, with: .color(color.opacity(0.3)))
                }
            }
        }
        .frame(width: digitWidth * scale, height: digitHeight * scale)
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(0..<10, id: \.self) { digit in
            SevenSegmentDigit(digit: digit, color: .white, scale: 1.0)
        }
    }
    .padding()
    .background(.black)
}
