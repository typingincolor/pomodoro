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
}
