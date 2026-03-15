@testable import Pomdoro

final class MockNotificationSender: NotificationSending, @unchecked Sendable {
    var sentNotifications: [(title: String, body: String)] = []

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}
