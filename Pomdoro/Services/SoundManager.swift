import AVFoundation
import AppKit

final class SoundManager: SoundPlaying, @unchecked Sendable {
    private var transitionPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var alarmTimer: Timer?
    private let settings: any SettingsStoring

    init(settings: any SettingsStoring) {
        self.settings = settings
    }

    func playTransitionBeep() {
        transitionPlayer = loadPlayer(named: settings.transitionSound, fallback: "transition-beep", loops: false)
        transitionPlayer?.numberOfLoops = 0
        transitionPlayer?.play()
    }

    func playCompletionAlarm() {
        alarmPlayer = loadPlayer(named: settings.completionSound, fallback: "completion-alarm", loops: true)
        alarmPlayer?.numberOfLoops = -1
        alarmPlayer?.play()

        alarmTimer?.invalidate()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
            self?.stopAlarm()
        }
    }

    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
        alarmPlayer?.stop()
        alarmPlayer = nil
        fallbackNSSound?.stop()
        fallbackNSSound = nil
    }

    private var fallbackNSSound: NSSound?

    private func loadPlayer(named name: String, fallback: String, loops: Bool) -> AVAudioPlayer? {
        let soundName = name.isEmpty ? fallback : name

        if let url = Bundle.main.url(forResource: soundName, withExtension: "aiff")
                ?? Bundle.main.url(forResource: soundName, withExtension: "mp3")
                ?? Bundle.main.url(forResource: soundName, withExtension: "wav") {
            return try? AVAudioPlayer(contentsOf: url)
        }

        if let nsSound = NSSound(named: soundName) {
            fallbackNSSound = nsSound
            nsSound.loops = loops
            nsSound.play()
        } else {
            NSSound.beep()
        }
        return nil
    }
}
