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
}
