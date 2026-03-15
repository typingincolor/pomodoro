import Foundation
@testable import Pomdoro

final class MockTimeProvider: TimeProvider, @unchecked Sendable {
    private var _now: Date

    init(now: Date = Date(timeIntervalSinceReferenceDate: 0)) {
        _now = now
    }

    var now: Date { _now }

    func advance(by seconds: TimeInterval) {
        _now = _now.addingTimeInterval(seconds)
    }
}
