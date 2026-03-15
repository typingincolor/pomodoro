import SwiftUI

struct ChainLinkButton: View {
    let isChained: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6 * scale) {
                Image(systemName: "link")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .strikethrough(!isChained, color: Color(white: 0.6))
                Text(isChained ? "Linked" : "Unlinked")
                    .font(.system(size: 11 * scale, weight: .medium))
            }
            .foregroundColor(isChained ? .orange : Color(white: 0.6))
            .padding(.horizontal, 12 * scale)
            .frame(height: 28 * scale)
            .background(
                RoundedRectangle(cornerRadius: 6 * scale)
                    .fill(isChained ? Color.orange.opacity(0.1) : Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * scale)
                            .stroke(isChained ? Color.orange.opacity(0.3) : Color(white: 0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("chainLinkButton")
        .animation(.easeInOut(duration: 0.2), value: isChained)
    }
}
