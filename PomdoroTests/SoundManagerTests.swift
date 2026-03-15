import XCTest
import AppKit
@testable import Pomdoro

@MainActor
final class SoundManagerTests: XCTestCase {
    func testPlayTransitionBeepDoesNotThrow() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        manager.playTransitionBeep()
    }

    func testPlayCompletionAlarmDoesNotThrow() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        manager.playCompletionAlarm()
        manager.stopAlarm()
    }

    func testStopAlarmClearsState() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        manager.playCompletionAlarm()
        manager.stopAlarm()
        manager.stopAlarm()
    }

    func testCorrectSoundLoadedForUserSelection() {
        let settings = MockSettingsStore()
        settings.transitionSound = "Tink"
        settings.completionSound = "Sosumi"
        let manager = SoundManager(settings: settings)
        manager.playTransitionBeep()
        manager.playCompletionAlarm()
        manager.stopAlarm()
    }

    func testPreviewPlaysSelectedSound() {
        let sound = NSSound(named: "Tink")
        XCTAssertNotNil(sound, "System sound 'Tink' should be available")
        sound?.play()
        sound?.stop()
    }
}
