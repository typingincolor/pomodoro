import Foundation

protocol TimeProvider: Sendable {
    var now: Date { get }
}

struct SystemTimeProvider: TimeProvider {
    var now: Date { Date() }
}
