import AVFoundation
import AppKit

@MainActor
final class SoundManager: SoundPlaying, @unchecked Sendable {
    private var alarmPlayer: AVAudioPlayer?
    private var fallbackNSSound: NSSound?

    func playAlarm() {
        if let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") {
            alarmPlayer = try? AVAudioPlayer(contentsOf: url)
            alarmPlayer?.numberOfLoops = -1
            alarmPlayer?.play()
        } else {
            NSSound.beep()
        }
    }

    func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
        fallbackNSSound?.stop()
        fallbackNSSound = nil
    }
}
