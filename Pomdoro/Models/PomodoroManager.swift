import Foundation

@MainActor
@Observable
final class PomodoroManager {
    let timer1: TimerModel
    let timer2: TimerModel
    var isChained = false

    private let soundPlayer: SoundPlaying
    private let notificationSender: NotificationSending
    let settings: any SettingsStoring

    init(
        timeProvider: TimeProvider = SystemTimeProvider(),
        soundPlayer: SoundPlaying,
        notificationSender: NotificationSending,
        settings: SettingsStoring
    ) {
        self.timer1 = TimerModel(timeProvider: timeProvider)
        self.timer2 = TimerModel(timeProvider: timeProvider)
        self.soundPlayer = soundPlayer
        self.notificationSender = notificationSender
        self.settings = settings
    }

    func playTimer1() { timer1.play() }
    func playTimer2() { timer2.play() }
    func pauseTimer1() { timer1.pause() }
    func pauseTimer2() { timer2.pause() }
    func resetTimer1() { timer1.reset() }
    func resetTimer2() { timer2.reset() }

    func tick() {
        timer1.tick()
        timer2.tick()
    }
}
