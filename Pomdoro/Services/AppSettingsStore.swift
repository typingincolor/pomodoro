import SwiftUI

@MainActor
@Observable
final class AppSettingsStore: SettingsStoring {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let digitColorHex = "digitColorHex"
        static let transitionSound = "transitionSound"
        static let completionSound = "completionSound"
        static let defaultT1Minutes = "defaultT1Minutes"
        static let defaultT1Seconds = "defaultT1Seconds"
        static let defaultT2Minutes = "defaultT2Minutes"
        static let defaultT2Seconds = "defaultT2Seconds"
        static let windowSize = "windowSize"
    }

    var digitColorHex: String {
        didSet { defaults.set(digitColorHex, forKey: Keys.digitColorHex) }
    }
    var transitionSound: String {
        didSet { defaults.set(transitionSound, forKey: Keys.transitionSound) }
    }
    var completionSound: String {
        didSet { defaults.set(completionSound, forKey: Keys.completionSound) }
    }
    var defaultT1Minutes: Int {
        didSet { defaults.set(defaultT1Minutes, forKey: Keys.defaultT1Minutes) }
    }
    var defaultT1Seconds: Int {
        didSet { defaults.set(defaultT1Seconds, forKey: Keys.defaultT1Seconds) }
    }
    var defaultT2Minutes: Int {
        didSet { defaults.set(defaultT2Minutes, forKey: Keys.defaultT2Minutes) }
    }
    var defaultT2Seconds: Int {
        didSet { defaults.set(defaultT2Seconds, forKey: Keys.defaultT2Seconds) }
    }
    var windowSize: WindowSize {
        didSet { defaults.set(windowSize.rawValue, forKey: Keys.windowSize) }
    }

    init() {
        defaults.register(defaults: [
            Keys.digitColorHex: "FFFFFF",
            Keys.transitionSound: "transition-beep",
            Keys.completionSound: "completion-alarm",
            Keys.defaultT1Minutes: 25,
            Keys.defaultT1Seconds: 0,
            Keys.defaultT2Minutes: 5,
            Keys.defaultT2Seconds: 0,
            Keys.windowSize: WindowSize.small.rawValue,
        ])

        self.digitColorHex = defaults.string(forKey: Keys.digitColorHex) ?? "FFFFFF"
        self.transitionSound = defaults.string(forKey: Keys.transitionSound) ?? "transition-beep"
        self.completionSound = defaults.string(forKey: Keys.completionSound) ?? "completion-alarm"
        self.defaultT1Minutes = defaults.integer(forKey: Keys.defaultT1Minutes)
        self.defaultT1Seconds = defaults.integer(forKey: Keys.defaultT1Seconds)
        self.defaultT2Minutes = defaults.integer(forKey: Keys.defaultT2Minutes)
        self.defaultT2Seconds = defaults.integer(forKey: Keys.defaultT2Seconds)
        self.windowSize = WindowSize(rawValue: defaults.string(forKey: Keys.windowSize) ?? "small") ?? .small
    }
}
