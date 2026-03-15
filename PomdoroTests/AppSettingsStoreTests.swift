import XCTest
@testable import Pomdoro

@MainActor
final class AppSettingsStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        for key in ["digitColorHex",
                     "defaultT1Minutes", "defaultT1Seconds",
                     "defaultT2Minutes", "defaultT2Seconds", "windowSize"] {
            defaults.removeObject(forKey: key)
        }
    }

    func testDefaultValues() {
        let store = AppSettingsStore()
        XCTAssertEqual(store.digitColorHex, "FFFFFF")
        XCTAssertEqual(store.defaultT1Minutes, 25)
        XCTAssertEqual(store.defaultT1Seconds, 0)
        XCTAssertEqual(store.windowSize, .small)
    }

    func testPersistenceRoundTrip() {
        let store1 = AppSettingsStore()
        store1.digitColorHex = "00FF00"
        store1.defaultT1Minutes = 15
        store1.windowSize = .large

        let store2 = AppSettingsStore()
        XCTAssertEqual(store2.digitColorHex, "00FF00")
        XCTAssertEqual(store2.defaultT1Minutes, 15)
        XCTAssertEqual(store2.windowSize, .large)
    }

    func testDigitColorComputedProperty() {
        let store = AppSettingsStore()
        store.digitColorHex = "FF0000"
        let _ = store.digitColor
    }
}
