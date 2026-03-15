import Foundation

final class SoundManager: SoundPlaying, @unchecked Sendable {
    private let settings: any SettingsStoring

    init(settings: any SettingsStoring) {
        self.settings = settings
    }

    func playTransitionBeep() {
        // Stub — full implementation in Phase 7
    }

    func playCompletionAlarm() {
        // Stub — full implementation in Phase 7
    }

    func stopAlarm() {
        // Stub — full implementation in Phase 7
    }
}
