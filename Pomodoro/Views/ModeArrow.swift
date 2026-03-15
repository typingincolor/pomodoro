import SwiftUI

struct ModeArrow: View {
    let mode: TimerMode
    let scale: CGFloat
    var label: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode == .countdown ? "▼" : "▲")
                .font(.system(size: 12 * scale))
                .foregroundColor(mode == .countdown ? .orange : Color(red: 0.3, green: 0.7, blue: 0.3))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("timer\(label)ModeArrow")
        .help(mode == .countdown ? "Countdown mode" : "Timer mode")
    }
}
