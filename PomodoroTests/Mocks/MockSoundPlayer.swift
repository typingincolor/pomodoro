@testable import Pomodoro

final class MockSoundPlayer: SoundPlaying, @unchecked Sendable {
    var alarmCount = 0
    var stopAlarmCount = 0

    func playAlarm() { alarmCount += 1 }
    func stopAlarm() { stopAlarmCount += 1 }
}
