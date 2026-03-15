import Foundation

@MainActor
protocol SoundPlaying: Sendable {
    func playAlarm()
    func stopAlarm()
}
