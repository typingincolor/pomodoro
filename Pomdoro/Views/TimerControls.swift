import SwiftUI

struct TimerControls: View {
    let isRunning: Bool
    let isCompleted: Bool
    let isPaused: Bool
    let scale: CGFloat
    let onPlay: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void

    private let buttonSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 6 * scale) {
            Button(action: isRunning ? onPause : onPlay) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(isRunning ? amberBackground : greenBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * scale)
                                .stroke(isRunning ? amberBorder : greenBorder, lineWidth: 1.5)
                        )
                    Text(isRunning ? "⏸" : "▶")
                        .font(.system(size: 16 * scale))
                        .foregroundColor(isRunning ? .orange : .green)
                }
            }
            .buttonStyle(.plain)
            .frame(width: buttonSize * scale, height: buttonSize * scale)

            Button(action: onReset) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(redBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * scale)
                                .stroke(redBorder, lineWidth: 1.5)
                        )
                    Text("↺")
                        .font(.system(size: 14 * scale))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)
            .frame(width: buttonSize * scale, height: buttonSize * scale)
            .disabled(isRunning && !isCompleted && !isPaused)
            .opacity((isPaused || isCompleted || !isRunning) ? 1.0 : 0.3)
        }
    }

    private var greenBackground: Color { Color(red: 0.04, green: 0.1, blue: 0.04) }
    private var greenBorder: Color { Color(red: 0.1, green: 0.23, blue: 0.1) }
    private var amberBackground: Color { Color(red: 0.1, green: 0.08, blue: 0.04) }
    private var amberBorder: Color { Color(red: 0.23, green: 0.18, blue: 0.1) }
    private var redBackground: Color { Color(red: 0.1, green: 0.04, blue: 0.04) }
    private var redBorder: Color { Color(red: 0.23, green: 0.1, blue: 0.1) }
}
