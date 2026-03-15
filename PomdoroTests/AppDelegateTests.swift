import XCTest
@testable import Pomdoro

@MainActor
final class AppDelegateTests: XCTestCase {
    func testAppDelegateExists() {
        let delegate = AppDelegate()
        XCTAssertNotNil(delegate)
    }
}
