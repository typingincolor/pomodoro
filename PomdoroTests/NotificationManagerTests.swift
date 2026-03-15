import XCTest
@testable import Pomdoro

final class NotificationManagerTests: XCTestCase {
    func testSendDoesNotThrow() {
        let manager = NotificationManager()
        manager.send(title: "Test", body: "Body")
    }
}
