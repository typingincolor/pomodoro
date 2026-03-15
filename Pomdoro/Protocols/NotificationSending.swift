protocol NotificationSending: Sendable {
    func send(title: String, body: String)
}
