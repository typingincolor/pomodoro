@testable import Pomdoro

final class MockSoundPlayer: SoundPlaying, @unchecked Sendable {
    var transitionBeepCount = 0
    var completionAlarmCount = 0
    var stopAlarmCount = 0

    func playTransitionBeep() { transitionBeepCount += 1 }
    func playCompletionAlarm() { completionAlarmCount += 1 }
    func stopAlarm() { stopAlarmCount += 1 }
}
