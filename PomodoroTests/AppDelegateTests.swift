import XCTest
@testable import Pomodoro

@MainActor
final class AppDelegateTests: XCTestCase {
    func testAppDelegateExists() {
        let delegate = AppDelegate()
        XCTAssertNotNil(delegate)
    }
}
