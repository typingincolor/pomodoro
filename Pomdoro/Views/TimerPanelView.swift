import SwiftUI

struct TimerPanelView: View {
    var timer: TimerModel
    let label: String
    let color: Color
    let scale: CGFloat
    let isFocused: Bool
    let showControls: Bool
    let onPlay: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onToggleMode: () -> Void

    @Binding var selectedField: TimerField?
    @Binding var pendingDigit: Int?

    var body: some View {
        HStack(spacing: 10 * scale) {
            ZStack {
                RoundedRectangle(cornerRadius: 10 * scale)
                    .fill(Color(white: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10 * scale)
                            .stroke(Color(white: 0.1), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 0)

                VStack(spacing: 0) {
                    HStack {
                        ModeArrow(mode: timer.mode, scale: scale, action: onToggleMode)
                        Spacer()
                        Text(label)
                            .font(.system(size: 10 * scale, weight: .semibold))
                            .foregroundColor(Color(white: 0.2))
                    }
                    .padding(.horizontal, 12 * scale)
                    .padding(.top, 8 * scale)

                    SevenSegmentDisplay(
                        minutes: timer.displayMinutes,
                        seconds: timer.displaySeconds,
                        color: color,
                        scale: scale,
                        selectedField: selectedField
                    )
                    .padding(.top, 6 * scale)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                handleDisplayTap(at: value.location)
                            }
                    )

                    HStack(spacing: 0) {
                        Spacer()
                        Text("M")
                            .font(.system(size: 9 * scale))
                            .foregroundColor(Color(white: 0.27))
                            .textCase(.uppercase)
                        Spacer()
                        Spacer()
                        Text("S")
                            .font(.system(size: 9 * scale))
                            .foregroundColor(Color(white: 0.27))
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.bottom, 8 * scale)
                }
            }
            .frame(width: 220 * scale)
            .overlay(
                RoundedRectangle(cornerRadius: 10 * scale)
                    .stroke(isFocused ? color.opacity(0.2) : .clear, lineWidth: 2)
            )

            if showControls {
                TimerControls(
                    isRunning: timer.isRunning,
                    isCompleted: timer.isCompleted,
                    isPaused: !timer.isRunning && timer.displayMinutes + timer.displaySeconds > 0,
                    scale: scale,
                    onPlay: onPlay,
                    onPause: onPause,
                    onReset: onReset
                )
            }
        }
    }

    private func handleDisplayTap(at location: CGPoint) {
        guard !timer.isRunning else { return }
        let midpoint = 140 * scale
        if location.x < midpoint {
            if selectedField == .minutes {
                selectedField = nil
                pendingDigit = nil
            } else {
                selectedField = .minutes
                pendingDigit = nil
            }
        } else {
            if selectedField == .seconds {
                selectedField = nil
                pendingDigit = nil
            } else {
                selectedField = .seconds
                pendingDigit = nil
            }
        }
    }
}
