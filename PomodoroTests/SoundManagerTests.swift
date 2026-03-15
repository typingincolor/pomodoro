import XCTest
import AppKit
@testable import Pomodoro

@MainActor
final class SoundManagerTests: XCTestCase {
    func testPlayAlarmDoesNotThrow() {
        let manager = SoundManager()
        manager.playAlarm()
        manager.stopAlarm()
    }

    func testStopAlarmClearsState() {
        let manager = SoundManager()
        manager.playAlarm()
        manager.stopAlarm()
        manager.stopAlarm()
    }
}
