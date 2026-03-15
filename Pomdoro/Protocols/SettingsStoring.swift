import SwiftUI

enum WindowSize: String, CaseIterable, Sendable {
    case small, medium, large, xl

    var width: CGFloat {
        switch self {
        case .small: 280
        case .medium: 360
        case .large: 460
        case .xl: 580
        }
    }

    var scaleFactor: CGFloat {
        width / 280.0
    }
}

@MainActor
protocol SettingsStoring: AnyObject {
    var digitColorHex: String { get set }
    var transitionSound: String { get set }
    var completionSound: String { get set }
    var defaultT1Minutes: Int { get set }
    var defaultT1Seconds: Int { get set }
    var defaultT2Minutes: Int { get set }
    var defaultT2Seconds: Int { get set }
    var windowSize: WindowSize { get set }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let int = UInt64(hex, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

extension SettingsStoring {
    var digitColor: Color {
        get { Color(hex: digitColorHex) ?? .white }
        set { digitColorHex = newValue.hexString }
    }
}
