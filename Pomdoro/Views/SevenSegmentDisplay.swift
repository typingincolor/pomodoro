import SwiftUI

struct SevenSegmentDisplay: View {
    let minutes: Int
    let seconds: Int
    let color: Color
    let scale: CGFloat
    var selectedField: TimerField? = nil

    private var minuteTens: Int { min(minutes, 99) / 10 }
    private var minuteOnes: Int { min(minutes, 99) % 10 }
    private var secondTens: Int { min(seconds, 59) / 10 }
    private var secondOnes: Int { min(seconds, 59) % 10 }

    var body: some View {
        HStack(spacing: 4 * scale) {
            digitPair(tens: minuteTens, ones: minuteOnes, field: .minutes)
            colonView
            digitPair(tens: secondTens, ones: secondOnes, field: .seconds)
        }
    }

    @ViewBuilder
    private func digitPair(tens: Int, ones: Int, field: TimerField) -> some View {
        let isSelected = selectedField == field

        HStack(spacing: 2 * scale) {
            SevenSegmentDigit(digit: tens, color: color, scale: scale)
            SevenSegmentDigit(digit: ones, color: color, scale: scale)
        }
        .padding(.horizontal, 4 * scale)
        .padding(.vertical, 2 * scale)
        .overlay(
            RoundedRectangle(cornerRadius: 4 * scale)
                .stroke(isSelected ? color.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }

    private var colonView: some View {
        VStack(spacing: 10 * scale) {
            Circle()
                .fill(color)
                .frame(width: 4 * scale, height: 4 * scale)
            Circle()
                .fill(color)
                .frame(width: 4 * scale, height: 4 * scale)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SevenSegmentDisplay(minutes: 25, seconds: 0, color: .white, scale: 1.0)
        SevenSegmentDisplay(minutes: 5, seconds: 30, color: .green, scale: 1.5,
                           selectedField: .minutes)
    }
    .padding()
    .background(.black)
}
