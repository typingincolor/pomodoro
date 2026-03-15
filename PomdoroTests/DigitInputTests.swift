import XCTest
@testable import Pomdoro

@MainActor
final class DigitInputTests: XCTestCase {
    var timeProvider: MockTimeProvider!
    var timer: TimerModel!

    override func setUp() {
        timeProvider = MockTimeProvider()
        timer = TimerModel(timeProvider: timeProvider)
    }

    func testSetTimeMinutesClampsTo99() {
        timer.setTime(minutes: 120, seconds: 0)
        XCTAssertEqual(timer.displayMinutes, 99)
    }

    func testSetTimeSecondsClampsTo59() {
        timer.setTime(minutes: 0, seconds: 75)
        XCTAssertEqual(timer.displaySeconds, 59)
    }

    func testSetTimeUpdatesDisplay() {
        timer.setTime(minutes: 15, seconds: 30)
        XCTAssertEqual(timer.displayMinutes, 15)
        XCTAssertEqual(timer.displaySeconds, 30)
    }

    func testSetTimeWhileRunningIsIgnored() {
        timer.setTime(minutes: 5, seconds: 0)
        timer.mode = .countdown
        timer.play()
        timeProvider.advance(by: 1)
        timer.tick()
        XCTAssertEqual(timer.displayMinutes, 4, "Should have counted down 1 second")
        XCTAssertEqual(timer.displaySeconds, 59)
        timer.setTime(minutes: 10, seconds: 0)
        XCTAssertEqual(timer.displayMinutes, 4, "setTime should be ignored while running")
        XCTAssertEqual(timer.displaySeconds, 59)
    }
}
