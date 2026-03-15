import SwiftUI

struct ChainLinkButton: View {
    let isChained: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isChained ? "link" : "link.slash")
                .font(.system(size: 14 * scale))
                .foregroundColor(isChained ? .orange : Color.gray.opacity(0.5))
                .frame(width: 32 * scale, height: 32 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 6 * scale)
                        .fill(Color(white: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6 * scale)
                                .stroke(Color(white: 0.1), lineWidth: 1)
                        )
                )
                .opacity(isChained ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("chainLinkButton")
        .animation(.easeInOut(duration: 0.2), value: isChained)
    }
}
