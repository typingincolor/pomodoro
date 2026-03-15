import XCTest
@testable import Pomdoro

final class SevenSegmentDigitTests: XCTestCase {
    func testDigitZeroSegments() {
        let segments = SevenSegmentDigit.segmentMap[0]
        XCTAssertEqual(segments, [true, true, true, true, true, true, false])
    }

    func testDigitOneSegments() {
        let segments = SevenSegmentDigit.segmentMap[1]
        XCTAssertEqual(segments, [false, true, true, false, false, false, false])
    }

    func testDigitEightSegments() {
        let segments = SevenSegmentDigit.segmentMap[8]
        XCTAssertEqual(segments, [true, true, true, true, true, true, true])
    }

    func testAllDigitsHaveSevenSegments() {
        for digit in 0...9 {
            XCTAssertEqual(SevenSegmentDigit.segmentMap[digit].count, 7, "Digit \(digit) should have 7 segments")
        }
    }

    func testClampedDigitBelowZero() {
        let clamped = min(max(-1, 0), 9)
        XCTAssertEqual(clamped, 0)
    }

    func testClampedDigitAboveNine() {
        let clamped = min(max(15, 0), 9)
        XCTAssertEqual(clamped, 9)
    }
}
