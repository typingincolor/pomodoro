import Foundation

protocol SoundPlaying: Sendable {
    func playTransitionBeep()
    func playCompletionAlarm()
    func stopAlarm()
}
