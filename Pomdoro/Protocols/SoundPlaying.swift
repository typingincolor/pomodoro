import Foundation

@MainActor
protocol SoundPlaying: Sendable {
    func playTransitionBeep()
    func playCompletionAlarm()
    func stopAlarm()
}
