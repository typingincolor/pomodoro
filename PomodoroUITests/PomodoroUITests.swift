import XCTest

final class PomodoroUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app.terminate()
    }

    private func openTimerPanel() {
        let menuBarItem = app.menuBarItems["timer"]
        if menuBarItem.exists {
            menuBarItem.click()
        }
    }

    func testAppLaunchesWithTimerPanel() {
        openTimerPanel()
        let t1PlayPause = app.buttons["timerT1PlayPause"]
        XCTAssertTrue(t1PlayPause.waitForExistence(timeout: 5), "T1 play button should exist")
        let t2PlayPause = app.buttons["timerT2PlayPause"]
        XCTAssertTrue(t2PlayPause.waitForExistence(timeout: 5), "T2 play button should exist")
        let chainButton = app.buttons["chainLinkButton"]
        XCTAssertTrue(chainButton.waitForExistence(timeout: 5), "Chain button should exist")
    }

    func testModeToggle() {
        openTimerPanel()
        let modeArrow = app.buttons["timerT1ModeArrow"]
        guard modeArrow.waitForExistence(timeout: 5) else {
            XCTFail("Mode arrow not found")
            return
        }
        let initialLabel = modeArrow.label
        modeArrow.click()
        XCTAssertNotEqual(modeArrow.label, initialLabel, "Mode arrow label should change after toggle")
    }

    func testChainToggle() {
        openTimerPanel()
        let chainButton = app.buttons["chainLinkButton"]
        guard chainButton.waitForExistence(timeout: 5) else {
            XCTFail("Chain button not found")
            return
        }
        chainButton.click()
        let t2PlayPause = app.buttons["timerT2PlayPause"]
        let disappeared = t2PlayPause.waitForNonExistence(timeout: 2)
        XCTAssertTrue(disappeared, "T2 play/pause should disappear when chained")
        chainButton.click()
        XCTAssertTrue(app.buttons["timerT2PlayPause"].waitForExistence(timeout: 2))
    }

    func testPauseAndResume() {
        openTimerPanel()
        let playButton = app.buttons["timerT1PlayPause"]
        let display = app.otherElements["timerT1Display"]
        guard playButton.waitForExistence(timeout: 5) else {
            XCTFail("Play button not found")
            return
        }
        playButton.click()
        sleep(1)
        playButton.click()
        let pausedValue = display.value as? String ?? ""
        sleep(1)
        let stillPausedValue = display.value as? String ?? ""
        XCTAssertEqual(pausedValue, stillPausedValue, "Display should not change while paused")
        playButton.click()
        sleep(1)
        playButton.click()
        let resumedValue = display.value as? String ?? ""
        XCTAssertNotEqual(pausedValue, resumedValue, "Display should have changed after resuming")
    }

    func testReset() {
        openTimerPanel()
        let playButton = app.buttons["timerT1PlayPause"]
        let resetButton = app.buttons["timerT1Reset"]
        let display = app.otherElements["timerT1Display"]
        guard playButton.waitForExistence(timeout: 5),
              resetButton.waitForExistence(timeout: 5) else {
            XCTFail("Buttons not found")
            return
        }
        let initialValue = display.value as? String ?? ""
        playButton.click()
        sleep(2)
        playButton.click()
        resetButton.click()
        let resetValue = display.value as? String ?? ""
        XCTAssertEqual(initialValue, resetValue, "Display should return to initial value after reset")
    }

    func testInputDisabledWhileRunning() {
        openTimerPanel()
        let playButton = app.buttons["timerT1PlayPause"]
        let display = app.otherElements["timerT1Display"]
        guard playButton.waitForExistence(timeout: 5) else {
            XCTFail("Play button not found")
            return
        }
        let t1Minutes = app.otherElements["timerT1Minutes"]
        let preStartValue = display.value as? String ?? ""
        playButton.click()
        sleep(1)
        if t1Minutes.exists {
            t1Minutes.click()
            t1Minutes.typeText("99")
            sleep(1)
        }
        playButton.click()
        if t1Minutes.exists {
            let minutesValue = t1Minutes.value as? String ?? ""
            XCTAssertNotEqual(minutesValue, "99",
                "Typing digits while timer is running should be ignored")
        }
    }

    func testCountUpMode() {
        openTimerPanel()
        let modeArrow = app.buttons["timerT1ModeArrow"]
        guard modeArrow.waitForExistence(timeout: 5) else {
            XCTFail("Mode arrow not found")
            return
        }
        modeArrow.click()
        let display = app.otherElements["timerT1Display"]
        let playButton = app.buttons["timerT1PlayPause"]
        playButton.click()
        sleep(3)
        playButton.click()
        let displayValue = display.value as? String ?? "00:00"
        XCTAssertNotEqual(displayValue, "00:00", "Count-up timer should have elapsed past 00:00")
    }

    func testChainedFlow() {
        openTimerPanel()
        let chainButton = app.buttons["chainLinkButton"]
        guard chainButton.waitForExistence(timeout: 5) else {
            XCTFail("Chain button not found")
            return
        }
        chainButton.click()
        let t1Minutes = app.otherElements["timerT1Minutes"]
        if t1Minutes.waitForExistence(timeout: 2) {
            t1Minutes.click()
            t1Minutes.typeText("00")
        }
        let t1Seconds = app.otherElements["timerT1Seconds"]
        if t1Seconds.waitForExistence(timeout: 2) {
            t1Seconds.click()
            t1Seconds.typeText("03")
        }
        let playButton = app.buttons["timerT1PlayPause"]
        guard playButton.waitForExistence(timeout: 5) else {
            XCTFail("Play button not found")
            return
        }
        playButton.click()
        sleep(5)
        let t2Display = app.otherElements["timerT2Display"]
        if t2Display.exists {
            let t2Value = t2Display.value as? String ?? "00:00"
            XCTAssertNotEqual(t2Value, "", "T2 display should have a value")
        }
        let t1Display = app.otherElements["timerT1Display"]
        if t1Display.exists {
            let t1Value = t1Display.value as? String ?? ""
            XCTAssertEqual(t1Value, "00:00", "T1 should show 00:00 after completion")
        }
        playButton.click()
    }

    func testDigitInput() {
        openTimerPanel()
        let t1Minutes = app.otherElements["timerT1Minutes"]
        guard t1Minutes.waitForExistence(timeout: 5) else {
            XCTFail("T1 minutes display not found")
            return
        }
        t1Minutes.click()
        t1Minutes.typeText("15")
        let t1Seconds = app.otherElements["timerT1Seconds"]
        guard t1Seconds.waitForExistence(timeout: 5) else {
            XCTFail("T1 seconds display not found")
            return
        }
        t1Seconds.click()
        t1Seconds.typeText("30")
        let t1Display = app.otherElements["timerT1Display"]
        if t1Display.exists {
            let displayValue = t1Display.value as? String ?? ""
            XCTAssertTrue(displayValue.contains("15") || displayValue.contains("30"),
                "Display should reflect entered digits, got: \(displayValue)")
        }
        let minutesValue = t1Minutes.value as? String ?? ""
        XCTAssertEqual(minutesValue, "15", "Minutes should show 15 after typing '15'")
        let secondsValue = t1Seconds.value as? String ?? ""
        XCTAssertEqual(secondsValue, "30", "Seconds should show 30 after typing '30'")
    }

    func testWindowSizeSwitching() {
        openTimerPanel()
        let settingsButton = app.buttons["settingsButton"]
        guard settingsButton.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.click()
        let largeButton = app.radioButtons["windowSizeLarge"]
        guard largeButton.waitForExistence(timeout: 5) else {
            XCTFail("Window size 'Large' radio button not found")
            return
        }
        largeButton.click()
        sleep(1)
        XCTAssertTrue(largeButton.isSelected || (largeButton.value as? Bool == true),
            "Large window size radio button should be selected after clicking")
    }
}
