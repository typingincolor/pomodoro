import SwiftUI
@testable import Pomdoro

@MainActor
final class MockSettingsStore: SettingsStoring {
    var digitColorHex: String = "FFFFFF"
    var defaultT1Minutes: Int = 25
    var defaultT1Seconds: Int = 0
    var defaultT2Minutes: Int = 5
    var defaultT2Seconds: Int = 0
    var windowSize: WindowSize = .small
}
