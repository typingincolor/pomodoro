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

    func testResetCountdown() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 20, seconds: 0)
        timer.mode = .countdown

        timer.play()
        timeProvider.advance(by: 300)
        timer.tick()
        timer.pause()
        timer.reset()

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.displayMinutes, 20)
        XCTAssertEqual(timer.displaySeconds, 0)
    }

    func testResetCountUp() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.mode = .countUp

        timer.play()
        timeProvider.advance(by: 125)
        timer.tick()
        timer.pause()
        timer.reset()

        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.displayMinutes, 0)
        XCTAssertEqual(timer.displaySeconds, 0)
    }

    func testTimeClampingMinutes() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 150, seconds: 0)
        XCTAssertEqual(timer.displayMinutes, 99)
        XCTAssertEqual(timer.displaySeconds, 0)
    }

    func testTimeClampingSeconds() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 5, seconds: 75)
        XCTAssertEqual(timer.displayMinutes, 5)
        XCTAssertEqual(timer.displaySeconds, 59)
    }

    func testTimeClampingNegative() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: -5, seconds: -10)
        XCTAssertEqual(timer.displayMinutes, 0)
        XCTAssertEqual(timer.displaySeconds, 0)
    }

    func testCountdownAtZeroDoesNotStart() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 0, seconds: 0)
        timer.mode = .countdown

        timer.play()
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isCompleted)
    }

    func testCountdownCompletionFlag() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 0, seconds: 5)
        timer.mode = .countdown

        timer.play()
        timeProvider.advance(by: 5)
        timer.tick()

        XCTAssertTrue(timer.isCompleted)
        XCTAssertEqual(timer.displayMinutes, 0)
        XCTAssertEqual(timer.displaySeconds, 0)
    }

    func testCountUpClampsAt99Minutes59Seconds() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.mode = .countUp

        timer.play()
        timeProvider.advance(by: 6000) // 100 minutes
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 99)
        XCTAssertEqual(timer.displaySeconds, 59)
    }

    func testCountUpStaysClampedBeyond99Minutes59Seconds() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.mode = .countUp

        timer.play()
        timeProvider.advance(by: 7200) // 120 minutes
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 99)
        XCTAssertEqual(timer.displaySeconds, 59)
    }
}
