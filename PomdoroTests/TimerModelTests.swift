import XCTest
@testable import Pomdoro

@MainActor
final class TimerModelTests: XCTestCase {
    var timeProvider: MockTimeProvider!

    override func setUp() {
        timeProvider = MockTimeProvider()
    }

    func testCountdownElapsedTime() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 5, seconds: 0)
        timer.mode = .countdown

        timer.play()
        timeProvider.advance(by: 90) // 1:30 elapsed
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 3)
        XCTAssertEqual(timer.displaySeconds, 30)
    }

    func testCountUpElapsedTime() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.mode = .countUp

        timer.play()
        timeProvider.advance(by: 125) // 2:05
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 2)
        XCTAssertEqual(timer.displaySeconds, 5)
    }

    func testPauseAndResume() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 10, seconds: 0)
        timer.mode = .countdown

        timer.play()
        timeProvider.advance(by: 60)
        timer.tick()
        timer.pause()

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.displayMinutes, 9)
        XCTAssertEqual(timer.displaySeconds, 0)

        timeProvider.advance(by: 300)
        timer.tick()
        XCTAssertEqual(timer.displayMinutes, 9)
        XCTAssertEqual(timer.displaySeconds, 0)

        timer.play()
        timeProvider.advance(by: 30)
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 8)
        XCTAssertEqual(timer.displaySeconds, 30)
    }
}
