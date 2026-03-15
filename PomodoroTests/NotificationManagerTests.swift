import XCTest
@testable import Pomodoro

final class NotificationManagerTests: XCTestCase {
    func testSendDoesNotThrow() {
        let manager = NotificationManager()
        manager.send(title: "Test", body: "Body")
    }
}
