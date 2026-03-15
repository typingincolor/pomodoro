import Foundation

@MainActor
@Observable
final class PomodoroManager {
    let timer1: TimerModel
    let timer2: TimerModel
    var isChained = false
    private(set) var chainPhase: ChainPhase = .idle

    enum ChainPhase: Equatable {
        case idle, timer1Running, timer2Running, completed
    }

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

    func toggleChain() {
        isChained.toggle()
        if isChained {
            timer1.mode = .countdown
            timer2.mode = .countdown
        }
    }

    func playChained() {
        guard isChained else { return }
        if chainPhase == .idle {
            chainPhase = .timer1Running
            timer1.play()
        } else {
            resumeChained()
        }
    }

    func pauseChained() {
        guard isChained else { return }
        switch chainPhase {
        case .timer1Running: timer1.pause()
        case .timer2Running: timer2.pause()
        default: break
        }
    }

    func resumeChained() {
        guard isChained else { return }
        switch chainPhase {
        case .timer1Running: timer1.play()
        case .timer2Running: timer2.play()
        default: break
        }
    }

    func resetChained() {
        guard isChained else { return }
        timer1.reset()
        timer2.reset()
        chainPhase = .idle
    }

    func tick() {
        timer1.tick()
        timer2.tick()
        if isChained {
            handleChainedTick()
        } else {
            handleUnchainedTick()
        }
    }

    private func handleChainedTick() {
        if chainPhase == .timer1Running && timer1.isCompleted {
            chainPhase = .timer2Running
            soundPlayer.playTransitionBeep()
            notificationSender.send(title: "Timer 1 complete", body: "Timer 2 started")
            timer2.play()
        }
        if chainPhase == .timer2Running && timer2.isCompleted {
            chainPhase = .completed
            soundPlayer.playCompletionAlarm()
            notificationSender.send(title: "Timer complete!", body: "")
        }
    }

    private func handleUnchainedTick() {
        if timer1.isCompleted {
            soundPlayer.playCompletionAlarm()
            notificationSender.send(title: "Timer complete!", body: "Timer 1 finished")
        }
        if timer2.isCompleted {
            soundPlayer.playCompletionAlarm()
            notificationSender.send(title: "Timer complete!", body: "Timer 2 finished")
        }
    }
}
