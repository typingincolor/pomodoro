import XCTest
@testable import Pomdoro

@MainActor
final class PomodoroManagerTests: XCTestCase {
    var timeProvider: MockTimeProvider!
    var soundPlayer: MockSoundPlayer!
    var notificationSender: MockNotificationSender!
    var settingsStore: MockSettingsStore!
    var manager: PomodoroManager!

    override func setUp() {
        timeProvider = MockTimeProvider()
        soundPlayer = MockSoundPlayer()
        notificationSender = MockNotificationSender()
        settingsStore = MockSettingsStore()
        manager = PomodoroManager(
            timeProvider: timeProvider,
            soundPlayer: soundPlayer,
            notificationSender: notificationSender,
            settings: settingsStore
        )
    }

    func testUnchainedTimersOperateIndependently() {
        XCTAssertFalse(manager.isChained)

        manager.timer1.setTime(minutes: 10, seconds: 0)
        manager.timer1.mode = .countdown
        manager.timer2.setTime(minutes: 5, seconds: 0)
        manager.timer2.mode = .countdown

        manager.playTimer1()
        timeProvider.advance(by: 60)
        manager.tick()

        XCTAssertEqual(manager.timer1.displayMinutes, 9)
        XCTAssertEqual(manager.timer2.displayMinutes, 5)
        XCTAssertTrue(manager.timer1.isRunning)
        XCTAssertFalse(manager.timer2.isRunning)
    }

    func testChainingForcesCountdownMode() {
        manager.timer1.mode = .countUp
        manager.timer2.mode = .countUp
        manager.toggleChain()
        XCTAssertTrue(manager.isChained)
        XCTAssertEqual(manager.timer1.mode, .countdown)
        XCTAssertEqual(manager.timer2.mode, .countdown)
    }

    func testUnchainRestoresIndependence() {
        manager.toggleChain()
        manager.toggleChain()
        XCTAssertFalse(manager.isChained)
    }

    func testChainedT1CompletionStartsT2() {
        manager.toggleChain()
        manager.timer1.setTime(minutes: 0, seconds: 5)
        manager.timer2.setTime(minutes: 0, seconds: 10)
        manager.playChained()
        timeProvider.advance(by: 5)
        manager.tick()
        XCTAssertTrue(manager.timer1.isCompleted)
        XCTAssertTrue(manager.timer2.isRunning)
        XCTAssertEqual(soundPlayer.transitionBeepCount, 1)
        XCTAssertEqual(notificationSender.sentNotifications.count, 1)
        XCTAssertEqual(notificationSender.sentNotifications.first?.title, "Timer 1 complete")
    }

    func testChainedT2CompletionTriggersAlarm() {
        manager.toggleChain()
        manager.timer1.setTime(minutes: 0, seconds: 3)
        manager.timer2.setTime(minutes: 0, seconds: 5)
        manager.playChained()
        timeProvider.advance(by: 3)
        manager.tick()
        timeProvider.advance(by: 5)
        manager.tick()
        XCTAssertTrue(manager.timer2.isCompleted)
        XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
        XCTAssertEqual(notificationSender.sentNotifications.count, 2)
    }

    func testChainedPausePausesActiveTimer() {
        manager.toggleChain()
        manager.timer1.setTime(minutes: 0, seconds: 10)
        manager.timer2.setTime(minutes: 0, seconds: 5)
        manager.playChained()
        timeProvider.advance(by: 3)
        manager.tick()
        manager.pauseChained()
        XCTAssertFalse(manager.timer1.isRunning)
        XCTAssertEqual(manager.timer1.displaySeconds, 7)
        manager.playChained()
        XCTAssertTrue(manager.timer1.isRunning)
    }

    func testChainedResetResetsBothTimers() {
        manager.toggleChain()
        manager.timer1.setTime(minutes: 5, seconds: 0)
        manager.timer2.setTime(minutes: 3, seconds: 0)
        manager.playChained()
        timeProvider.advance(by: 60)
        manager.tick()
        manager.pauseChained()
        manager.resetChained()
        XCTAssertEqual(manager.timer1.displayMinutes, 5)
        XCTAssertEqual(manager.timer2.displayMinutes, 3)
        XCTAssertEqual(manager.chainPhase, .idle)
    }

    func testStandaloneCompletionTriggersAlarm() {
        manager.timer1.setTime(minutes: 0, seconds: 3)
        manager.timer1.mode = .countdown
        manager.playTimer1()
        timeProvider.advance(by: 3)
        manager.tick()
        XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
        XCTAssertEqual(notificationSender.sentNotifications.count, 1)
        timeProvider.advance(by: 1)
        manager.tick()
        XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
    }
}
