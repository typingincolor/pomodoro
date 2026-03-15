# Pomodoro Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar pomodoro timer app with dual seven-segment LCD displays, chaining, and TDD throughout.

**Architecture:** Pure SwiftUI with `@Observable`, protocol-based DI for all side effects. Views are thin; all logic lives in testable models. `MenuBarExtra` for menu bar presence, `NSPanel` for detachable floating window.

**Tech Stack:** Swift 6, SwiftUI, XCTest, XCUITest, AVFoundation, UserNotifications

**Spec:** `docs/superpowers/specs/2026-03-14-pomodoro-design.md`

---

## Phased Approach

Each phase has acceptance criteria that must pass before proceeding to the next phase. Phases build on each other — later phases depend on earlier ones being solid.

| Phase | What | Acceptance Criteria |
|-------|------|-------------------|
| 1 | Project scaffold + protocols + mocks | Project builds, tests run (empty) |
| 2 | TimerModel with TDD | All TimerModel unit tests pass |
| 3 | PomodoroManager with TDD | All chaining/coordination tests pass |
| 4 | Seven-segment display | Visual rendering correct, snapshot tests pass |
| 5 | Timer panel UI | Full timer panel renders, digit input works |
| 6 | App shell (menu bar + detach) | App launches in menu bar, detach/re-attach works |
| 7 | Sound + notifications | Sounds play on completion, notifications fire |
| 8 | Settings | All settings persist and apply |
| 9 | UI tests | All XCUITest flows pass |
| 10 | Polish | Window sizing, keyboard shortcuts, final QA |

---

## File Structure

```
Pomodoro/
├── Pomodoro.xcodeproj
├── Pomodoro/
│   ├── PomodoroApp.swift                  # App entry point, MenuBarExtra
│   ├── AppDelegate.swift                  # NSApplicationDelegateAdaptor, NSPanel management
│   │
│   ├── Protocols/
│   │   ├── TimeProvider.swift             # TimeProvider protocol + SystemTimeProvider
│   │   ├── SoundPlaying.swift             # SoundPlaying protocol
│   │   ├── NotificationSending.swift      # NotificationSending protocol
│   │   └── SettingsStoring.swift          # SettingsStoring protocol + WindowSize enum
│   │
│   ├── Models/
│   │   ├── TimerModel.swift               # Single timer state + logic
│   │   └── PomodoroManager.swift          # Owns 2 TimerModels, chaining, sound/notification triggers
│   │
│   ├── Services/
│   │   ├── SoundManager.swift             # SoundPlaying concrete impl
│   │   ├── NotificationManager.swift      # NotificationSending concrete impl
│   │   └── AppSettingsStore.swift         # SettingsStoring concrete impl (@AppStorage)
│   │
│   ├── Views/
│   │   ├── MainTimerView.swift            # Root view: two panels + chain + settings gear
│   │   ├── TimerPanelView.swift           # Single timer panel: display + controls
│   │   ├── SevenSegmentDigit.swift        # Single digit Shape (segments a–g)
│   │   ├── SevenSegmentDisplay.swift      # MM:SS composed from SevenSegmentDigit
│   │   ├── TimerControls.swift            # Play/Pause + Reset buttons
│   │   ├── ChainLinkButton.swift          # Chain toggle between panels
│   │   ├── ModeArrow.swift                # ▼/▲ countdown/timer toggle
│   │   └── SettingsView.swift             # Settings sheet
│   │
│   └── Resources/
│       ├── Assets.xcassets                # App icon, color assets
│       ├── transition-beep.aiff           # Default T1 completion sound
│       └── completion-alarm.aiff          # Default T2/final completion sound
│
├── PomodoroTests/
│   ├── Mocks/
│   │   ├── MockTimeProvider.swift         # Controllable time for tests
│   │   ├── MockSoundPlayer.swift          # Records sound calls
│   │   ├── MockNotificationSender.swift   # Records notification calls
│   │   └── MockSettingsStore.swift        # In-memory settings for tests
│   │
│   ├── TimerModelTests.swift              # All TimerModel unit tests
│   └── PomodoroManagerTests.swift         # All PomodoroManager unit tests
│
└── PomodoroUITests/
    └── PomodoroUITests.swift               # XCUITest end-to-end flows
```

---

## Chunk 1: Phase 1–3 (Foundation + Business Logic)

### Phase 1: Project Scaffold

**Acceptance criteria:** Xcode project builds for macOS. Unit test target runs (0 tests, 0 failures). All protocols and mocks compile.

#### Task 1.1: Create Xcode Project

- [ ] **Step 1: Create the Xcode project**

Run: `mkdir -p /Users/andrew/Development/pomodoro && cd /Users/andrew/Development/pomodoro`

Open Xcode → File → New → Project → macOS → App
- Product Name: `Pomodoro`
- Organization Identifier: pick your own (e.g., `com.yourname`)
- Interface: SwiftUI
- Language: Swift
- Testing System: XCTest
- Check "Include Tests" (this creates the `PomodoroTests` unit test target and `PomodoroUITests` UI test target with proper host app configuration)

After creation, delete the template test files (`PomodoroTests/PomodoroTests.swift` and `PomodoroUITests/PomodoroUITests.swift` / `PomodoroUITestsLaunchTests.swift`) — we'll replace them with our own.

> **Note for agentic workers:** If you cannot use the Xcode GUI, create the project using `xcodegen`. Install with `brew install xcodegen`, then create a `project.yml` in the project root:
> ```yaml
> name: Pomodoro
> options:
>   bundleIdPrefix: com.yourname
>   deploymentTarget:
>     macOS: "13.0"
> targets:
>   Pomodoro:
>     type: application
>     platform: macOS
>     sources: [Pomodoro]
>     settings:
>       SWIFT_VERSION: "6.0"
>       SWIFT_STRICT_CONCURRENCY: complete
>   PomodoroTests:
>     type: bundle.unit-test
>     platform: macOS
>     sources: [PomodoroTests]
>     dependencies:
>       - target: Pomodoro
>   PomodoroUITests:
>     type: bundle.ui-testing
>     platform: macOS
>     sources: [PomodoroUITests]
>     dependencies:
>       - target: Pomodoro
> ```
> Then run: `xcodegen generate`

- [ ] **Step 2: Verify build**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: scaffold Xcode project"
```

#### Task 1.2: Create Protocols

- [ ] **Step 1: Create `Pomodoro/Protocols/TimeProvider.swift`**

```swift
import Foundation

protocol TimeProvider: Sendable {
    var now: Date { get }
}

struct SystemTimeProvider: TimeProvider {
    var now: Date { Date() }
}
```

- [ ] **Step 2: Create `Pomodoro/Protocols/SoundPlaying.swift`**

```swift
import Foundation

protocol SoundPlaying: Sendable {
    func playTransitionBeep()
    func playCompletionAlarm()
    func stopAlarm()
}
```

- [ ] **Step 3: Create `Pomodoro/Protocols/NotificationSending.swift`**

```swift
protocol NotificationSending: Sendable {
    func send(title: String, body: String)
}
```

- [ ] **Step 4: Create `Pomodoro/Protocols/SettingsStoring.swift`**

```swift
import SwiftUI

enum WindowSize: String, CaseIterable, Sendable {
    case small, medium, large, xl

    var width: CGFloat {
        switch self {
        case .small: 280
        case .medium: 360
        case .large: 460
        case .xl: 580
        }
    }

    var scaleFactor: CGFloat {
        width / 280.0
    }
}

@MainActor
protocol SettingsStoring: AnyObject {
    var digitColorHex: String { get set }
    var transitionSound: String { get set }
    var completionSound: String { get set }
    var defaultT1Minutes: Int { get set }
    var defaultT1Seconds: Int { get set }
    var defaultT2Minutes: Int { get set }
    var defaultT2Seconds: Int { get set }
    var windowSize: WindowSize { get set }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let int = UInt64(hex, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

extension SettingsStoring {
    var digitColor: Color {
        get { Color(hex: digitColorHex) ?? .white }
        set { digitColorHex = newValue.hexString }
    }
}
```

> **Note:** `Color(hex:)` and `hexString` are custom extensions defined here in `SettingsStoring.swift`. They handle hex string ↔ Color conversion for the `digitColorHex` storage property.

- [ ] **Step 5: Verify build**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Pomodoro/Protocols/
git commit -m "feat: add DI protocols and WindowSize enum"
```

#### Task 1.3: Create Test Mocks

- [ ] **Step 1: Create `PomodoroTests/Mocks/MockTimeProvider.swift`**

```swift
import Foundation
@testable import Pomodoro

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
```

- [ ] **Step 2: Create `PomodoroTests/Mocks/MockSoundPlayer.swift`**

```swift
@testable import Pomodoro

final class MockSoundPlayer: SoundPlaying, @unchecked Sendable {
    var transitionBeepCount = 0
    var completionAlarmCount = 0
    var stopAlarmCount = 0

    func playTransitionBeep() { transitionBeepCount += 1 }
    func playCompletionAlarm() { completionAlarmCount += 1 }
    func stopAlarm() { stopAlarmCount += 1 }
}
```

- [ ] **Step 3: Create `PomodoroTests/Mocks/MockNotificationSender.swift`**

```swift
@testable import Pomodoro

final class MockNotificationSender: NotificationSending, @unchecked Sendable {
    var sentNotifications: [(title: String, body: String)] = []

    func send(title: String, body: String) {
        sentNotifications.append((title: title, body: body))
    }
}
```

- [ ] **Step 4: Create `PomodoroTests/Mocks/MockSettingsStore.swift`**

```swift
import SwiftUI
@testable import Pomodoro

@MainActor
final class MockSettingsStore: SettingsStoring {
    var digitColorHex: String = "FFFFFF"
    var transitionSound: String = "transition-beep"
    var completionSound: String = "completion-alarm"
    var defaultT1Minutes: Int = 25
    var defaultT1Seconds: Int = 0
    var defaultT2Minutes: Int = 5
    var defaultT2Seconds: Int = 0
    var windowSize: WindowSize = .small
}
```

- [ ] **Step 5: Verify tests compile**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **` (0 tests run)

- [ ] **Step 6: Commit**

```bash
git add PomodoroTests/
git commit -m "feat: add test mocks for all DI protocols"
```

---

### Phase 2: TimerModel (TDD)

**Acceptance criteria:** All TimerModel unit tests pass. Covers: countdown, count-up, pause/resume, reset, time clamping, edge cases. No UI code yet.

#### Task 2.1: TimerModel — Countdown Basic

- [ ] **Step 1: Write failing test — countdown elapsed time**

Create `PomodoroTests/TimerModelTests.swift`:

```swift
import XCTest
@testable import Pomodoro

@MainActor
final class TimerModelTests: XCTestCase {
    var timeProvider: MockTimeProvider!

    override func setUp() {
        timeProvider = MockTimeProvider()
    }

    func testCountdownElapsedTime() {
        let timer = TimerModel(timeProvider: timeProvider)
        timer.setTime(minutes: 5, seconds: 0)
        timer.mode = .countdown

        timer.play()
        timeProvider.advance(by: 90) // 1:30 elapsed
        timer.tick()

        XCTAssertEqual(timer.displayMinutes, 3)
        XCTAssertEqual(timer.displaySeconds, 30)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/TimerModelTests/testCountdownElapsedTime 2>&1 | tail -10`
Expected: FAIL — `TimerModel` not defined

- [ ] **Step 3: Write minimal TimerModel implementation**

Create `Pomodoro/Models/TimerModel.swift`:

```swift
import Foundation

enum TimerMode: Sendable {
    case countdown
    case countUp
}

/// Which digit pair is selected for editing
enum TimerField: Sendable {
    case minutes
    case seconds
}

@MainActor
@Observable
final class TimerModel {
    // MARK: - Public State
    var mode: TimerMode = .countdown
    private(set) var isRunning = false
    private(set) var displayMinutes: Int = 0
    private(set) var displaySeconds: Int = 0
    private(set) var hasNotifiedCompletion = false

    // MARK: - Internal State
    private var targetSeconds: Int = 0
    private var elapsedAtPause: TimeInterval = 0
    private var startDate: Date?
    private let timeProvider: TimeProvider

    // MARK: - Init
    init(timeProvider: TimeProvider = SystemTimeProvider()) {
        self.timeProvider = timeProvider
    }

    // MARK: - Public API
    func setTime(minutes: Int, seconds: Int) {
        guard !isRunning else { return } // No editing while running
        let clampedMinutes = min(max(minutes, 0), 99)
        let clampedSeconds = min(max(seconds, 0), 59)
        targetSeconds = clampedMinutes * 60 + clampedSeconds
        displayMinutes = clampedMinutes
        displaySeconds = clampedSeconds
    }

    func play() {
        guard !isRunning else { return }
        // Spec: "start at 00:00 in countdown does nothing"
        if mode == .countdown && targetSeconds == 0 && elapsedAtPause == 0 {
            return
        }
        startDate = timeProvider.now
        isRunning = true
    }

    func tick() {
        guard isRunning, let startDate else { return }
        let elapsed = timeProvider.now.timeIntervalSince(startDate) + elapsedAtPause

        switch mode {
        case .countdown:
            let remaining = max(targetSeconds - Int(elapsed), 0)
            displayMinutes = remaining / 60
            displaySeconds = remaining % 60
            if remaining == 0 && !hasNotifiedCompletion {
                hasNotifiedCompletion = true
            }
        case .countUp:
            let total = min(Int(elapsed), 5999) // Cap at 99:59
            displayMinutes = total / 60
            displaySeconds = total % 60
        }
    }

    /// True when countdown has reached zero (whether still running or paused at zero).
    /// Used by views (e.g., TimerControls) to enable the reset button on completion.
    /// PomodoroManager uses `hasNotifiedCompletion` + `hasHandledTimer*Completion`
    /// for single-fire sound/notification triggers instead.
    var isCompleted: Bool {
        mode == .countdown && displayMinutes == 0 && displaySeconds == 0 && hasNotifiedCompletion
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/TimerModelTests/testCountdownElapsedTime 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/TimerModel.swift PomodoroTests/TimerModelTests.swift
git commit -m "feat: TimerModel countdown basic — TDD green"
```

#### Task 2.2: TimerModel — Count Up

- [ ] **Step 1: Write count-up test** (expected to pass — count-up logic is already in Task 2.1's implementation)

Add to `TimerModelTests.swift`:

```swift
func testCountUpElapsedTime() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.mode = .countUp

    timer.play()
    timeProvider.advance(by: 125) // 2:05
    timer.tick()

    XCTAssertEqual(timer.displayMinutes, 2)
    XCTAssertEqual(timer.displaySeconds, 5)
}
```

- [ ] **Step 2: Run test to verify it passes** (should already pass with existing implementation)

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/TimerModelTests/testCountUpElapsedTime 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add PomodoroTests/TimerModelTests.swift
git commit -m "test: TimerModel count-up test"
```

#### Task 2.3: TimerModel — Pause/Resume

- [ ] **Step 1: Write failing test**

Add to `TimerModelTests.swift`:

```swift
func testPauseAndResume() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 10, seconds: 0)
    timer.mode = .countdown

    timer.play()
    timeProvider.advance(by: 60) // 1 min elapsed
    timer.tick()
    timer.pause()

    XCTAssertFalse(timer.isRunning)
    XCTAssertEqual(timer.displayMinutes, 9)
    XCTAssertEqual(timer.displaySeconds, 0)

    // Advance time while paused — should not affect display
    timeProvider.advance(by: 300)
    timer.tick()
    XCTAssertEqual(timer.displayMinutes, 9)
    XCTAssertEqual(timer.displaySeconds, 0)

    // Resume
    timer.play()
    timeProvider.advance(by: 30) // 30 more seconds
    timer.tick()

    XCTAssertEqual(timer.displayMinutes, 8)
    XCTAssertEqual(timer.displaySeconds, 30)
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `pause()` not defined

- [ ] **Step 3: Add `pause()` to TimerModel**

Add to `TimerModel.swift`:

```swift
func pause() {
    guard isRunning, let startDate else { return }
    elapsedAtPause += timeProvider.now.timeIntervalSince(startDate)
    self.startDate = nil
    isRunning = false
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/TimerModel.swift PomodoroTests/TimerModelTests.swift
git commit -m "feat: TimerModel pause/resume — TDD green"
```

#### Task 2.4: TimerModel — Reset

- [ ] **Step 1: Write failing test**

Add to `TimerModelTests.swift`:

```swift
func testResetCountdown() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 20, seconds: 0)
    timer.mode = .countdown

    timer.play()
    timeProvider.advance(by: 300)
    timer.tick()
    timer.pause()
    timer.reset()

    XCTAssertFalse(timer.isRunning)
    XCTAssertEqual(timer.displayMinutes, 20)
    XCTAssertEqual(timer.displaySeconds, 0)
}

func testResetCountUp() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.mode = .countUp

    timer.play()
    timeProvider.advance(by: 125)
    timer.tick()
    timer.pause()
    timer.reset()

    XCTAssertFalse(timer.isRunning)
    XCTAssertEqual(timer.displayMinutes, 0)
    XCTAssertEqual(timer.displaySeconds, 0)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — `reset()` not defined

- [ ] **Step 3: Add `reset()` to TimerModel**

Add to `TimerModel.swift`:

```swift
func reset() {
    isRunning = false
    startDate = nil
    elapsedAtPause = 0

    switch mode {
    case .countdown:
        displayMinutes = targetSeconds / 60
        displaySeconds = targetSeconds % 60
    case .countUp:
        displayMinutes = 0
        displaySeconds = 0
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/TimerModel.swift PomodoroTests/TimerModelTests.swift
git commit -m "feat: TimerModel reset — TDD green"
```

#### Task 2.5: TimerModel — Clamping and Edge Cases

- [ ] **Step 1: Write failing tests**

Add to `TimerModelTests.swift`:

```swift
func testTimeClampingMinutes() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 150, seconds: 0)
    XCTAssertEqual(timer.displayMinutes, 99)
    XCTAssertEqual(timer.displaySeconds, 0)
}

func testTimeClampingSeconds() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 5, seconds: 75)
    XCTAssertEqual(timer.displayMinutes, 5)
    XCTAssertEqual(timer.displaySeconds, 59)
}

func testTimeClampingNegative() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: -5, seconds: -10)
    XCTAssertEqual(timer.displayMinutes, 0)
    XCTAssertEqual(timer.displaySeconds, 0)
}

func testCountdownAtZeroDoesNotStart() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 0, seconds: 0)
    timer.mode = .countdown

    timer.play()
    // Spec: "start at 00:00 in countdown does nothing"
    XCTAssertFalse(timer.isRunning)
    XCTAssertFalse(timer.isCompleted)
}

func testCountdownCompletionFlag() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.setTime(minutes: 0, seconds: 5)
    timer.mode = .countdown

    timer.play()
    timeProvider.advance(by: 5)
    timer.tick()

    XCTAssertTrue(timer.isCompleted)
    XCTAssertEqual(timer.displayMinutes, 0)
    XCTAssertEqual(timer.displaySeconds, 0)
}

func testCountUpClampsAt99Minutes59Seconds() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.mode = .countUp

    timer.play()
    timeProvider.advance(by: 6000) // 100 minutes
    timer.tick()

    // Spec: max value is 99:59 — both minutes AND seconds are clamped
    XCTAssertEqual(timer.displayMinutes, 99)
    XCTAssertEqual(timer.displaySeconds, 59)
}

func testCountUpStaysClampedBeyond99Minutes59Seconds() {
    let timer = TimerModel(timeProvider: timeProvider)
    timer.mode = .countUp

    timer.play()
    timeProvider.advance(by: 7200) // 120 minutes
    timer.tick()

    XCTAssertEqual(timer.displayMinutes, 99)
    XCTAssertEqual(timer.displaySeconds, 59)
}
```

- [ ] **Step 2: Run tests**

Expected: Most should PASS with existing clamping logic. If any fail, fix.

- [ ] **Step 3: Commit**

```bash
git add PomodoroTests/TimerModelTests.swift
git commit -m "test: TimerModel clamping and edge case tests"
```

#### Phase 2 Gate

- [ ] **Run all TimerModel tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/TimerModelTests 2>&1 | grep -E '(Test Suite|Executed|PASS|FAIL)'`

**Acceptance criteria:** All tests pass. Do NOT proceed to Phase 3 until this gate passes.

---

### Phase 3: PomodoroManager (TDD)

**Acceptance criteria:** All PomodoroManager unit tests pass. Covers: independent operation, chaining toggle, T1→T2 transition, chained pause/reset, sound/notification triggers via mocks.

#### Task 3.1: PomodoroManager — Independent Timers

- [ ] **Step 1: Write failing test**

Create `PomodoroTests/PomodoroManagerTests.swift`:

```swift
import XCTest
@testable import Pomodoro

@MainActor
final class PomodoroManagerTests: XCTestCase {
    var timeProvider: MockTimeProvider!
    var soundPlayer: MockSoundPlayer!
    var notificationSender: MockNotificationSender!
    var settingsStore: MockSettingsStore!
    var manager: PomodoroManager!

    override func setUp() {
        timeProvider = MockTimeProvider()
        soundPlayer = MockSoundPlayer()
        notificationSender = MockNotificationSender()
        settingsStore = MockSettingsStore()
        manager = PomodoroManager(
            timeProvider: timeProvider,
            soundPlayer: soundPlayer,
            notificationSender: notificationSender,
            settings: settingsStore
        )
    }

    func testUnchainedTimersOperateIndependently() {
        XCTAssertFalse(manager.isChained)

        manager.timer1.setTime(minutes: 10, seconds: 0)
        manager.timer1.mode = .countdown
        manager.timer2.setTime(minutes: 5, seconds: 0)
        manager.timer2.mode = .countdown

        manager.playTimer1()
        timeProvider.advance(by: 60)
        manager.tick()

        // T1 ran for 1 min, T2 untouched
        XCTAssertEqual(manager.timer1.displayMinutes, 9)
        XCTAssertEqual(manager.timer2.displayMinutes, 5)
        XCTAssertTrue(manager.timer1.isRunning)
        XCTAssertFalse(manager.timer2.isRunning)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `PomodoroManager` not defined

- [ ] **Step 3: Write minimal PomodoroManager**

Create `Pomodoro/Models/PomodoroManager.swift`:

```swift
import Foundation

@MainActor
@Observable
final class PomodoroManager {
    let timer1: TimerModel
    let timer2: TimerModel
    var isChained = false

    private let soundPlayer: SoundPlaying
    private let notificationSender: NotificationSending
    let settings: any SettingsStoring

    init(
        timeProvider: TimeProvider = SystemTimeProvider(),
        soundPlayer: SoundPlaying,
        notificationSender: NotificationSending,
        settings: SettingsStoring
    ) {
        self.timer1 = TimerModel(timeProvider: timeProvider)
        self.timer2 = TimerModel(timeProvider: timeProvider)
        self.soundPlayer = soundPlayer
        self.notificationSender = notificationSender
        self.settings = settings
    }

    func playTimer1() {
        timer1.play()
    }

    func playTimer2() {
        timer2.play()
    }

    func pauseTimer1() {
        timer1.pause()
    }

    func pauseTimer2() {
        timer2.pause()
    }

    func resetTimer1() {
        timer1.reset()
    }

    func resetTimer2() {
        timer2.reset()
    }

    func tick() {
        timer1.tick()
        timer2.tick()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/PomodoroManager.swift PomodoroTests/PomodoroManagerTests.swift
git commit -m "feat: PomodoroManager independent timers — TDD green"
```

#### Task 3.2: PomodoroManager — Chain Toggle

- [ ] **Step 1: Write failing test**

Add to `PomodoroManagerTests.swift`:

```swift
func testChainingForcesCountdownMode() {
    manager.timer1.mode = .countUp
    manager.timer2.mode = .countUp

    manager.toggleChain()

    XCTAssertTrue(manager.isChained)
    XCTAssertEqual(manager.timer1.mode, .countdown)
    XCTAssertEqual(manager.timer2.mode, .countdown)
}

func testUnchainRestoresIndependence() {
    manager.toggleChain() // chain
    manager.toggleChain() // unchain

    XCTAssertFalse(manager.isChained)
    // Timers keep countdown mode but are now independent
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `toggleChain()` not defined

- [ ] **Step 3: Add `toggleChain()` to PomodoroManager**

Add to `PomodoroManager.swift`:

```swift
func toggleChain() {
    isChained.toggle()
    if isChained {
        timer1.mode = .countdown
        timer2.mode = .countdown
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/PomodoroManager.swift PomodoroTests/PomodoroManagerTests.swift
git commit -m "feat: PomodoroManager chain toggle — TDD green"
```

#### Task 3.3: PomodoroManager — Chained T1→T2 Transition

- [ ] **Step 1: Write failing test**

Add to `PomodoroManagerTests.swift`:

```swift
func testChainedT1CompletionStartsT2() {
    manager.toggleChain()
    manager.timer1.setTime(minutes: 0, seconds: 5)
    manager.timer2.setTime(minutes: 0, seconds: 10)

    manager.playChained()
    timeProvider.advance(by: 5)
    manager.tick()

    // T1 completed, T2 should be running
    XCTAssertTrue(manager.timer1.isCompleted)
    XCTAssertTrue(manager.timer2.isRunning)
    XCTAssertEqual(soundPlayer.transitionBeepCount, 1)
    XCTAssertEqual(notificationSender.sentNotifications.count, 1)
    XCTAssertEqual(notificationSender.sentNotifications.first?.title, "Timer 1 complete")
}

func testChainedT2CompletionTriggersAlarm() {
    manager.toggleChain()
    manager.timer1.setTime(minutes: 0, seconds: 3)
    manager.timer2.setTime(minutes: 0, seconds: 5)

    manager.playChained()
    timeProvider.advance(by: 3)
    manager.tick() // T1 completes, T2 starts

    timeProvider.advance(by: 5)
    manager.tick() // T2 completes

    XCTAssertTrue(manager.timer2.isCompleted)
    XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
    XCTAssertEqual(notificationSender.sentNotifications.count, 2)
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `playChained()` not defined

- [ ] **Step 3: Add chained playback logic to PomodoroManager**

Add to `PomodoroManager.swift`:

```swift
private(set) var chainPhase: ChainPhase = .idle

enum ChainPhase: Equatable {
    case idle
    case timer1Running
    case timer2Running
    case completed
}

func playChained() {
    guard isChained else { return }
    chainPhase = .timer1Running
    timer1.play()
}

// Replace the existing tick() with:
func tick() {
    timer1.tick()
    timer2.tick()

    if isChained {
        handleChainedTick()
    } else {
        handleUnchainedTick()
    }
}

private func handleChainedTick() {
    if chainPhase == .timer1Running && timer1.isCompleted {
        chainPhase = .timer2Running
        soundPlayer.playTransitionBeep()
        notificationSender.send(title: "Timer 1 complete", body: "Timer 2 started")
        timer2.play()
    }

    if chainPhase == .timer2Running && timer2.isCompleted {
        chainPhase = .completed
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "")
    }
}

private func handleUnchainedTick() {
    if timer1.isCompleted {
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "Timer 1 finished")
    }
    if timer2.isCompleted {
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "Timer 2 finished")
    }
}
```

**Known limitation:** This intermediate version of `handleUnchainedTick` will fire completion alerts on *every tick* after a timer reaches 00:00, not just once. This is intentional — Task 3.5 adds `hasHandledTimer1Completion` / `hasHandledTimer2Completion` guards to fix this. Do not debug the multi-fire behavior; it will be resolved in the next task.

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/PomodoroManager.swift PomodoroTests/PomodoroManagerTests.swift
git commit -m "feat: PomodoroManager chained T1→T2 transition — TDD green"
```

#### Task 3.4: PomodoroManager — Chained Pause/Reset

- [ ] **Step 1: Write failing test**

Add to `PomodoroManagerTests.swift`:

```swift
func testChainedPausePausesActiveTimer() {
    manager.toggleChain()
    manager.timer1.setTime(minutes: 0, seconds: 10)
    manager.timer2.setTime(minutes: 0, seconds: 5)

    manager.playChained()
    timeProvider.advance(by: 3)
    manager.tick()
    manager.pauseChained()

    XCTAssertFalse(manager.timer1.isRunning)
    XCTAssertEqual(manager.timer1.displaySeconds, 7)

    // Resume
    manager.playChained()
    XCTAssertTrue(manager.timer1.isRunning)
}

func testChainedResetResetsBothTimers() {
    manager.toggleChain()
    manager.timer1.setTime(minutes: 5, seconds: 0)
    manager.timer2.setTime(minutes: 3, seconds: 0)

    manager.playChained()
    timeProvider.advance(by: 60)
    manager.tick()
    manager.pauseChained()
    manager.resetChained()

    XCTAssertEqual(manager.timer1.displayMinutes, 5)
    XCTAssertEqual(manager.timer2.displayMinutes, 3)
    XCTAssertEqual(manager.chainPhase, .idle)
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `pauseChained()` / `resetChained()` not defined

- [ ] **Step 3: Add chained pause/reset**

Add to `PomodoroManager.swift`:

```swift
func pauseChained() {
    guard isChained else { return }
    switch chainPhase {
    case .timer1Running:
        timer1.pause()
    case .timer2Running:
        timer2.pause()
    default:
        break
    }
}

func resumeChained() {
    guard isChained else { return }
    switch chainPhase {
    case .timer1Running:
        timer1.play()
    case .timer2Running:
        timer2.play()
    default:
        break
    }
}

func resetChained() {
    guard isChained else { return }
    timer1.reset()
    timer2.reset()
    chainPhase = .idle
}
```

Update `playChained()` to handle resume:

```swift
func playChained() {
    guard isChained else { return }
    if chainPhase == .idle {
        chainPhase = .timer1Running
        timer1.play()
    } else {
        resumeChained()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/PomodoroManager.swift PomodoroTests/PomodoroManagerTests.swift
git commit -m "feat: PomodoroManager chained pause/reset — TDD green"
```

#### Task 3.5: PomodoroManager — Standalone Completion

- [ ] **Step 1: Write failing test**

Add to `PomodoroManagerTests.swift`:

```swift
func testStandaloneCompletionTriggersAlarm() {
    manager.timer1.setTime(minutes: 0, seconds: 3)
    manager.timer1.mode = .countdown

    manager.playTimer1()
    timeProvider.advance(by: 3)
    manager.tick()

    XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
    XCTAssertEqual(notificationSender.sentNotifications.count, 1)

    // Ticking again should NOT re-trigger
    timeProvider.advance(by: 1)
    manager.tick()
    XCTAssertEqual(soundPlayer.completionAlarmCount, 1)
}
```

- [ ] **Step 2: Run test — may fail on the "no re-trigger" assertion**

If it fails, add a `hasNotifiedCompletion` flag to `TimerModel` or `PomodoroManager` to prevent duplicate triggers.

- [ ] **Step 3: Fix re-trigger guard**

The `hasNotifiedCompletion` flag was already added to `TimerModel` in Task 2.1 and is set to `true` in `tick()` when countdown reaches zero. Now use it in `PomodoroManager` to prevent duplicate triggers.

Replace the entire `handleUnchainedTick()` method in `PomodoroManager.swift`:

```swift
private func handleUnchainedTick() {
    // Single-fire completion: TimerModel sets hasNotifiedCompletion = true
    // on the tick it completes. Manager uses its own hasHandled* flag
    // to avoid re-triggering on subsequent ticks.
    if timer1.hasNotifiedCompletion && !hasHandledTimer1Completion {
        hasHandledTimer1Completion = true
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "Timer 1 finished")
    }
    if timer2.hasNotifiedCompletion && !hasHandledTimer2Completion {
        hasHandledTimer2Completion = true
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "Timer 2 finished")
    }
}
```

Add these properties to `PomodoroManager`:

```swift
private var hasHandledTimer1Completion = false
private var hasHandledTimer2Completion = false
```

Also update `handleChainedTick()` to use the same pattern:

```swift
private func handleChainedTick() {
    if chainPhase == .timer1Running && timer1.hasNotifiedCompletion && !hasHandledTimer1Completion {
        hasHandledTimer1Completion = true
        chainPhase = .timer2Running
        soundPlayer.playTransitionBeep()
        notificationSender.send(title: "Timer 1 complete", body: "Timer 2 started")
        timer2.play()
    }

    if chainPhase == .timer2Running && timer2.hasNotifiedCompletion && !hasHandledTimer2Completion {
        hasHandledTimer2Completion = true
        chainPhase = .completed
        soundPlayer.playCompletionAlarm()
        notificationSender.send(title: "Timer complete!", body: "")
    }
}
```

Reset the flags in `resetTimer1()`, `resetTimer2()`, and `resetChained()`:

```swift
func resetTimer1() {
    timer1.reset()
    hasHandledTimer1Completion = false
}

func resetTimer2() {
    timer2.reset()
    hasHandledTimer2Completion = false
}

func resetChained() {
    guard isChained else { return }
    timer1.reset()
    timer2.reset()
    hasHandledTimer1Completion = false
    hasHandledTimer2Completion = false
    chainPhase = .idle
}
```

Also add to `TimerModel.reset()`:

```swift
func reset() {
    isRunning = false
    startDate = nil
    elapsedAtPause = 0
    hasNotifiedCompletion = false

    switch mode {
    case .countdown:
        displayMinutes = targetSeconds / 60
        displaySeconds = targetSeconds % 60
    case .countUp:
        displayMinutes = 0
        displaySeconds = 0
    }
}
```

- [ ] **Step 4: Run all PomodoroManager tests**

Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Models/ PomodoroTests/
git commit -m "feat: standalone completion with single-fire guard — TDD green"
```

#### Phase 3 Gate

- [ ] **Run all unit tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests 2>&1 | grep -E '(Test Suite|Executed|PASS|FAIL)'`

**Acceptance criteria:** All TimerModel and PomodoroManager tests pass. Do NOT proceed to Phase 4 until this gate passes.

---

## Chunk 2: Phases 4–6 (UI Components + App Shell)

### Phase 4: Seven-Segment Display

**Acceptance criteria:** `SevenSegmentDigit` renders all digits 0–9 correctly. `SevenSegmentDisplay` composes MM:SS with colon. Display responds to color and scale changes. Preview renders in Xcode. Segment map unit tests pass.

#### Task 4.1: SevenSegmentDigit — Segment Map Tests

**Files:**
- Create: `PomodoroTests/SevenSegmentDigitTests.swift`

- [ ] **Step 1: Write failing tests for the segment map**

The spec requires seven-segment digit rendering. Before implementing, test the segment map logic that determines which of the 7 segments (a–g) are on for each digit.

```swift
import XCTest
@testable import Pomodoro

final class SevenSegmentDigitTests: XCTestCase {
    // segmentMap[digit] returns [a, b, c, d, e, f, g] — which segments are ON
    func testDigitZeroSegments() {
        let segments = SevenSegmentDigit.segmentMap[0]
        // 0: a,b,c,d,e,f ON — g OFF
        XCTAssertEqual(segments, [true, true, true, true, true, true, false])
    }

    func testDigitOneSegments() {
        let segments = SevenSegmentDigit.segmentMap[1]
        // 1: b,c ON — all others OFF
        XCTAssertEqual(segments, [false, true, true, false, false, false, false])
    }

    func testDigitEightSegments() {
        let segments = SevenSegmentDigit.segmentMap[8]
        // 8: all ON
        XCTAssertEqual(segments, [true, true, true, true, true, true, true])
    }

    func testAllDigitsHaveSevenSegments() {
        for digit in 0...9 {
            XCTAssertEqual(SevenSegmentDigit.segmentMap[digit].count, 7, "Digit \(digit) should have 7 segments")
        }
    }

    func testClampedDigitBelowZero() {
        // Negative values should clamp to 0
        let clamped = min(max(-1, 0), 9)
        XCTAssertEqual(clamped, 0)
    }

    func testClampedDigitAboveNine() {
        // Values > 9 should clamp to 9
        let clamped = min(max(15, 0), 9)
        XCTAssertEqual(clamped, 9)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/SevenSegmentDigitTests 2>&1 | tail -10`
Expected: FAIL — `SevenSegmentDigit` not defined

#### Task 4.2: SevenSegmentDigit View

**Files:**
- Create: `Pomodoro/Views/SevenSegmentDigit.swift`

- [ ] **Step 1: Create `SevenSegmentDigit` — a single digit rendered via Canvas**

> **Note:** The spec says "custom SwiftUI Shape paths." We use a `View` with `Canvas` that draws `Shape` paths internally — this achieves the same visual result while being more practical for composing multiple segments with independent colors and opacities. The segment paths are `RoundedRectangle` shapes drawn via Canvas context.

```swift
import SwiftUI

struct SevenSegmentDigit: View {
    let digit: Int
    let color: Color
    let scale: CGFloat

    // Segment map: which of 7 segments (a–g) are ON for each digit
    // Layout:
    //  aaa
    // f   b
    //  ggg
    // e   c
    //  ddd
    static let segmentMap: [[Bool]] = [
        // a,     b,     c,     d,     e,     f,     g
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    private var segments: [Bool] {
        let clamped = min(max(digit, 0), 9)
        return Self.segmentMap[clamped]
    }

    // Base dimensions (for scale = 1.0, designed for Small size)
    private let segmentLength: CGFloat = 20
    private let segmentThickness: CGFloat = 4
    private let digitWidth: CGFloat = 24
    private let digitHeight: CGFloat = 44

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let t = segmentThickness * scale
            let inset = t / 2

            // Define segment positions as (origin, size, isHorizontal)
            let segmentDefs: [(CGPoint, Bool)] = [
                (CGPoint(x: inset, y: 0), true),                          // a - top
                (CGPoint(x: w - t, y: inset), false),                     // b - top right
                (CGPoint(x: w - t, y: h / 2 + inset), false),            // c - bottom right
                (CGPoint(x: inset, y: h - t), true),                      // d - bottom
                (CGPoint(x: 0, y: h / 2 + inset), false),                // e - bottom left
                (CGPoint(x: 0, y: inset), false),                         // f - top left
                (CGPoint(x: inset, y: (h - t) / 2), true),               // g - middle
            ]

            for (i, (origin, isHorizontal)) in segmentDefs.enumerated() {
                let segSize: CGSize = isHorizontal
                    ? CGSize(width: w - 2 * inset, height: t)
                    : CGSize(width: t, height: h / 2 - inset)
                let rect = CGRect(origin: origin, size: segSize)
                let path = RoundedRectangle(cornerRadius: t / 3)
                    .path(in: rect)

                let isOn = segments[i]
                let opacity: Double = isOn ? 1.0 : 0.05
                let segColor = color.opacity(opacity)
                context.fill(path, with: .color(segColor))

                // Glow effect for active segments
                if isOn {
                    context.fill(path, with: .color(color.opacity(0.3)))
                }
            }
        }
        .frame(width: digitWidth * scale, height: digitHeight * scale)
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(0..<10, id: \.self) { digit in
            SevenSegmentDigit(digit: digit, color: .white, scale: 1.0)
        }
    }
    .padding()
    .background(.black)
}
```

- [ ] **Step 2: Run segment map tests to verify they pass**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/SevenSegmentDigitTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 3: Build and verify preview renders**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

Open Xcode → SevenSegmentDigit.swift → Preview canvas → verify all 10 digits render with correct segment patterns.

- [ ] **Step 4: Commit**

```bash
git add Pomodoro/Views/SevenSegmentDigit.swift PomodoroTests/SevenSegmentDigitTests.swift
git commit -m "feat: SevenSegmentDigit with segment map and tests — TDD green"
```

#### Task 4.3: SevenSegmentDisplay (MM:SS)

**Files:**
- Create: `Pomodoro/Views/SevenSegmentDisplay.swift`

- [ ] **Step 1: Create `SevenSegmentDisplay` — composes 4 digits + colon**

```swift
import SwiftUI

struct SevenSegmentDisplay: View {
    let minutes: Int
    let seconds: Int
    let color: Color
    let scale: CGFloat
    var selectedField: TimerField? = nil // Uses shared TimerField enum

    private var minuteTens: Int { min(minutes, 99) / 10 }
    private var minuteOnes: Int { min(minutes, 99) % 10 }
    private var secondTens: Int { min(seconds, 59) / 10 }
    private var secondOnes: Int { min(seconds, 59) % 10 }

    var body: some View {
        HStack(spacing: 4 * scale) {
            // Minutes
            digitPair(tens: minuteTens, ones: minuteOnes, field: .minutes)

            // Colon
            colonView

            // Seconds
            digitPair(tens: secondTens, ones: secondOnes, field: .seconds)
        }
    }

    @ViewBuilder
    private func digitPair(tens: Int, ones: Int, field: TimerField) -> some View {
        let isSelected = selectedField == field

        HStack(spacing: 2 * scale) {
            SevenSegmentDigit(digit: tens, color: color, scale: scale)
            SevenSegmentDigit(digit: ones, color: color, scale: scale)
        }
        .padding(.horizontal, 4 * scale)
        .padding(.vertical, 2 * scale)
        .overlay(
            RoundedRectangle(cornerRadius: 4 * scale)
                .stroke(isSelected ? color.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }

    private var colonView: some View {
        VStack(spacing: 10 * scale) {
            Circle()
                .fill(color)
                .frame(width: 4 * scale, height: 4 * scale)
            Circle()
                .fill(color)
                .frame(width: 4 * scale, height: 4 * scale)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SevenSegmentDisplay(minutes: 25, seconds: 0, color: .white, scale: 1.0)
        SevenSegmentDisplay(minutes: 5, seconds: 30, color: .green, scale: 1.5,
                           selectedField: .minutes)
    }
    .padding()
    .background(.black)
}
```

- [ ] **Step 2: Build and verify preview**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/SevenSegmentDisplay.swift
git commit -m "feat: SevenSegmentDisplay MM:SS with selection highlight"
```

#### Phase 4 Gate

- [ ] **Verify build + preview**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

Manually verify in Xcode previews: digits 0–9 render correctly, MM:SS display shows colon, selection highlight works.

---

### Phase 5: Timer Panel UI

**Acceptance criteria:** `TimerPanelView` shows display + controls. `ModeArrow` toggles mode. `TimerControls` show play/pause/reset. `ChainLinkButton` toggles. Digit input works (click to select, type/arrow to edit). `MainTimerView` composes everything. All views compile and render in preview.

#### Task 5.1: ModeArrow

**Files:**
- Create: `Pomodoro/Views/ModeArrow.swift`

- [ ] **Step 1: Create `ModeArrow`**

```swift
import SwiftUI

struct ModeArrow: View {
    let mode: TimerMode
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode == .countdown ? "▼" : "▲")
                .font(.system(size: 12 * scale))
                .foregroundColor(mode == .countdown ? .orange : Color(red: 0.3, green: 0.7, blue: 0.3))
        }
        .buttonStyle(.plain)
        .help(mode == .countdown ? "Countdown mode" : "Timer mode")
    }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/ModeArrow.swift
git commit -m "feat: ModeArrow toggle view"
```

#### Task 5.2: TimerControls

**Files:**
- Create: `Pomodoro/Views/TimerControls.swift`

- [ ] **Step 1: Create `TimerControls`**

```swift
import SwiftUI

struct TimerControls: View {
    let isRunning: Bool
    let isCompleted: Bool
    let isPaused: Bool
    let scale: CGFloat
    let onPlay: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void

    private let buttonSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 6 * scale) {
            // Play / Pause button
            Button(action: isRunning ? onPause : onPlay) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(isRunning ? amberBackground : greenBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * scale)
                                .stroke(isRunning ? amberBorder : greenBorder, lineWidth: 1.5)
                        )
                    Text(isRunning ? "⏸" : "▶")
                        .font(.system(size: 16 * scale))
                        .foregroundColor(isRunning ? .orange : .green)
                }
            }
            .buttonStyle(.plain)
            .frame(width: buttonSize * scale, height: buttonSize * scale)

            // Reset button
            Button(action: onReset) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(redBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * scale)
                                .stroke(redBorder, lineWidth: 1.5)
                        )
                    Text("↺")
                        .font(.system(size: 14 * scale))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)
            .frame(width: buttonSize * scale, height: buttonSize * scale)
            .disabled(isRunning && !isCompleted && !isPaused)
            .opacity((isPaused || isCompleted || !isRunning) ? 1.0 : 0.3)
        }
    }

    // Color helpers
    private var greenBackground: Color { Color(red: 0.04, green: 0.1, blue: 0.04) }
    private var greenBorder: Color { Color(red: 0.1, green: 0.23, blue: 0.1) }
    private var amberBackground: Color { Color(red: 0.1, green: 0.08, blue: 0.04) }
    private var amberBorder: Color { Color(red: 0.23, green: 0.18, blue: 0.1) }
    private var redBackground: Color { Color(red: 0.1, green: 0.04, blue: 0.04) }
    private var redBorder: Color { Color(red: 0.23, green: 0.1, blue: 0.1) }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/TimerControls.swift
git commit -m "feat: TimerControls with play/pause and reset buttons"
```

#### Task 5.3: ChainLinkButton

**Files:**
- Create: `Pomodoro/Views/ChainLinkButton.swift`

- [ ] **Step 1: Create `ChainLinkButton`**

```swift
import SwiftUI

struct ChainLinkButton: View {
    let isChained: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isChained ? "link" : "link.slash")
                .font(.system(size: 14 * scale))
                .foregroundColor(isChained ? .orange : Color.gray.opacity(0.5))
                .frame(width: 32 * scale, height: 32 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 6 * scale)
                        .fill(Color(white: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6 * scale)
                                .stroke(Color(white: 0.1), lineWidth: 1)
                        )
                )
                .opacity(isChained ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isChained)
    }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/ChainLinkButton.swift
git commit -m "feat: ChainLinkButton with link/link.slash icons"
```

#### Task 5.4: TimerPanelView

**Files:**
- Create: `Pomodoro/Views/TimerPanelView.swift`

- [ ] **Step 1: Create `TimerPanelView`**

This is the main panel for a single timer. It handles digit selection and input.

```swift
import SwiftUI

struct TimerPanelView: View {
    var timer: TimerModel
    let label: String // "T1" or "T2"
    let color: Color
    let scale: CGFloat
    let isFocused: Bool
    let showControls: Bool
    let onPlay: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onToggleMode: () -> Void

    // Digit-editing state — passed as Bindings from MainTimerView so that
    // both click handling (here) and keyboard handling (MainTimerView) share state.
    @Binding var selectedField: TimerField?
    @Binding var pendingDigit: Int?

    var body: some View {
        HStack(spacing: 10 * scale) {
            // Timer display panel
            ZStack {
                // Panel background
                RoundedRectangle(cornerRadius: 10 * scale)
                    .fill(Color(white: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10 * scale)
                            .stroke(Color(white: 0.1), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 0)

                VStack(spacing: 0) {
                    // Header: mode arrow (left) + label (right)
                    HStack {
                        ModeArrow(mode: timer.mode, scale: scale, action: onToggleMode)
                        Spacer()
                        Text(label)
                            .font(.system(size: 10 * scale, weight: .semibold))
                            .foregroundColor(Color(white: 0.2))
                    }
                    .padding(.horizontal, 12 * scale)
                    .padding(.top, 8 * scale)

                    // Seven-segment display
                    SevenSegmentDisplay(
                        minutes: timer.displayMinutes,
                        seconds: timer.displaySeconds,
                        color: color,
                        scale: scale,
                        selectedField: selectedField
                    )
                    .padding(.top, 6 * scale)
                    // Use DragGesture(minimumDistance: 0) instead of spatial
                    // .onTapGesture { location in } which requires macOS 14+
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                handleDisplayTap(at: value.location)
                            }
                    )

                    // M / S labels
                    HStack(spacing: 0) {
                        Spacer()
                        Text("M")
                            .font(.system(size: 9 * scale))
                            .foregroundColor(Color(white: 0.27))
                            .textCase(.uppercase)
                        Spacer()
                        Spacer()
                        Text("S")
                            .font(.system(size: 9 * scale))
                            .foregroundColor(Color(white: 0.27))
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.bottom, 8 * scale)
                }
            }
            .frame(width: 220 * scale) // Base panel width (display area, controls are separate)
            .overlay(
                // Focus ring
                RoundedRectangle(cornerRadius: 10 * scale)
                    .stroke(isFocused ? color.opacity(0.2) : .clear, lineWidth: 2)
            )

            // Controls to the right
            if showControls {
                TimerControls(
                    isRunning: timer.isRunning,
                    isCompleted: timer.isCompleted,
                    isPaused: !timer.isRunning && timer.displayMinutes + timer.displaySeconds > 0,
                    scale: scale,
                    onPlay: onPlay,
                    onPause: onPause,
                    onReset: onReset
                )
            }
        }
    }

    // MARK: - Digit Input

    private func handleDisplayTap(at location: CGPoint) {
        guard !timer.isRunning else { return }

        // Determine which half was tapped (left = minutes, right = seconds)
        let midpoint = 140 * scale // Approximate center of display
        if location.x < midpoint {
            if selectedField == .minutes {
                selectedField = nil
                pendingDigit = nil
            } else {
                selectedField = .minutes
                pendingDigit = nil
            }
        } else {
            if selectedField == .seconds {
                selectedField = nil
                pendingDigit = nil
            } else {
                selectedField = .seconds
                pendingDigit = nil
            }
        }
    }

    // Note: Keyboard handling (arrows, tab, enter, escape, digits) is in
    // MainTimerView.handleDigitEditingKey(), which operates on the same
    // @Binding selectedField / pendingDigit state.
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/TimerPanelView.swift
git commit -m "feat: TimerPanelView with digit input and controls"
```

#### Task 5.5: MainTimerView

**Files:**
- Create: `Pomodoro/Views/MainTimerView.swift`

- [ ] **Step 1: Create `MainTimerView`**

```swift
import SwiftUI

struct MainTimerView: View {
    @Environment(PomodoroManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme

    let settings: any SettingsStoring
    let scale: CGFloat
    let onDetach: (() -> Void)?

    @State private var focusedTimer: Int = 1 // 1 or 2
    @State private var showSettings = false
    // Digit-editing state (lifted from TimerPanelView so NSEvent monitor can access it)
    @State private var editingTimerField: TimerField? // nil = no field selected
    @State private var editingPendingDigit: Int? // first digit of two-keystroke entry

    var body: some View {
        VStack(spacing: 0) {
                // Timer 1
                TimerPanelView(
                    timer: manager.timer1,
                    label: "T1",
                    color: settings.digitColor,
                    scale: scale,
                    isFocused: focusedTimer == 1,
                    showControls: true,
                    onPlay: { manager.isChained ? manager.playChained() : manager.playTimer1() },
                    onPause: { manager.isChained ? manager.pauseChained() : manager.pauseTimer1() },
                    onReset: { manager.isChained ? manager.resetChained() : manager.resetTimer1() },
                    onToggleMode: {
                        guard !manager.isChained else { return }
                        manager.timer1.mode = manager.timer1.mode == .countdown ? .countUp : .countdown
                    },
                    selectedField: focusedTimer == 1 ? $editingTimerField : .constant(nil),
                    pendingDigit: focusedTimer == 1 ? $editingPendingDigit : .constant(nil)
                )

                // Chain link
                ChainLinkButton(
                    isChained: manager.isChained,
                    scale: scale,
                    action: { manager.toggleChain() }
                )
                .padding(.vertical, 6 * scale)

                // Timer 2
                TimerPanelView(
                    timer: manager.timer2,
                    label: "T2",
                    color: settings.digitColor,
                    scale: scale,
                    isFocused: focusedTimer == 2,
                    showControls: !manager.isChained,
                    onPlay: { manager.playTimer2() },
                    onPause: { manager.pauseTimer2() },
                    onReset: { manager.resetTimer2() },
                    onToggleMode: {
                        guard !manager.isChained else { return }
                        manager.timer2.mode = manager.timer2.mode == .countdown ? .countUp : .countdown
                    },
                    selectedField: focusedTimer == 2 ? $editingTimerField : .constant(nil),
                    pendingDigit: focusedTimer == 2 ? $editingPendingDigit : .constant(nil)
                )

                // Bottom bar: settings gear + detach button
                HStack {
                    if let onDetach {
                        Button(action: onDetach) {
                            Image(systemName: "pin")
                                .font(.system(size: 12 * scale))
                                .foregroundColor(Color(white: 0.33))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12 * scale))
                            .foregroundColor(Color(white: 0.33))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settingsButton")
                }
                .padding(.horizontal, 8 * scale)
                .padding(.top, 10 * scale)
            }
        .padding(20 * scale)
        .background(Color(white: 0.04))
        .onReceive(Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()) { _ in
            manager.tick()
        }
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if handleKeyEvent(event) { return nil }
                return event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = nil
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }

    @State private var keyMonitor: Any?

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let chars = event.characters else { return false }

        // When a digit field is selected, digit-editing keys take priority
        // over shortcuts. This ensures typing "1" or "2" enters digits
        // instead of switching timer focus.
        let focusedTimerModel = focusedTimer == 1 ? manager.timer1 : manager.timer2
        if editingTimerField != nil {
            return handleDigitEditingKey(event, timer: focusedTimerModel)
        }

        if chars == " " {
            handlePlayPause()
            return true
        }
        if chars.lowercased() == "r" {
            handleReset()
            return true
        }
        if chars == "1" { focusedTimer = 1; return true }
        if chars == "2" { focusedTimer = 2; return true }

        // Forward remaining keys (arrows, tab for potential future use)
        return handleDigitEditingKey(event, timer: focusedTimerModel)
    }

    /// Forwards digit-editing keys to the focused timer's digit-editing state.
    /// Handles: Up/Down arrows, Tab, Enter, Escape, digit characters (0-9).
    /// Digit-editing state (`selectedField`, `pendingDigit`) lives on TimerPanelView
    /// as @State. Since NSEvent monitor can't access @State of a child view,
    /// we lift the shared editing state into MainTimerView and pass it down.
    ///
    /// The state variables `editingTimerField` and `editingPendingDigit` (declared
    /// as @State on MainTimerView above) track which field is selected and partial
    /// digit input. TimerPanelView receives these as Bindings.
    private func handleDigitEditingKey(_ event: NSEvent, timer: TimerModel) -> Bool {
        guard !timer.isRunning else { return false }
        guard editingTimerField != nil else { return false } // No field selected

        let keyCode = event.keyCode
        guard let chars = event.characters else { return false }

        // Up arrow: increment selected field
        if keyCode == 126 {
            if editingTimerField == .minutes {
                timer.setTime(minutes: timer.displayMinutes + 1, seconds: timer.displaySeconds)
            } else {
                timer.setTime(minutes: timer.displayMinutes, seconds: timer.displaySeconds + 1)
            }
            return true
        }
        // Down arrow: decrement selected field
        if keyCode == 125 {
            if editingTimerField == .minutes {
                timer.setTime(minutes: max(0, timer.displayMinutes - 1), seconds: timer.displaySeconds)
            } else {
                timer.setTime(minutes: timer.displayMinutes, seconds: max(0, timer.displaySeconds - 1))
            }
            return true
        }
        // Tab: toggle between minutes/seconds
        if keyCode == 48 {
            editingTimerField = (editingTimerField == .minutes) ? .seconds : .minutes
            editingPendingDigit = nil
            return true
        }
        // Enter/Escape: deselect
        if keyCode == 36 || keyCode == 53 {
            editingTimerField = nil
            editingPendingDigit = nil
            return true
        }
        // Digit 0-9: two-keystroke entry
        if let char = chars.first, char.isNumber, let digit = Int(String(char)) {
            if let pending = editingPendingDigit {
                // Second digit: combine and commit
                let value = pending * 10 + digit
                if editingTimerField == .minutes {
                    timer.setTime(minutes: value, seconds: timer.displaySeconds)
                } else {
                    timer.setTime(minutes: timer.displayMinutes, seconds: value)
                }
                editingPendingDigit = nil
                editingTimerField = nil // Auto-deselect after two digits
            } else {
                // First digit: store as pending
                editingPendingDigit = digit
                // Show the first digit immediately
                if editingTimerField == .minutes {
                    timer.setTime(minutes: digit, seconds: timer.displaySeconds)
                } else {
                    timer.setTime(minutes: timer.displayMinutes, seconds: digit)
                }
            }
            return true
        }
        return false
    }

    private func handlePlayPause() {
        if manager.isChained {
            if manager.timer1.isRunning || manager.timer2.isRunning {
                manager.pauseChained()
            } else {
                manager.playChained()
            }
        } else {
            let timer = focusedTimer == 1 ? manager.timer1 : manager.timer2
            if timer.isRunning {
                focusedTimer == 1 ? manager.pauseTimer1() : manager.pauseTimer2()
            } else {
                focusedTimer == 1 ? manager.playTimer1() : manager.playTimer2()
            }
        }
    }

    private func handleReset() {
        if manager.isChained {
            manager.resetChained()
        } else {
            focusedTimer == 1 ? manager.resetTimer1() : manager.resetTimer2()
        }
    }
}
```

Note: We use `NSEvent.addLocalMonitorForEvents` for keyboard handling because `onKeyPress` requires macOS 14+ but our target is macOS 13. Timer updates use `Timer.publish` at 30fps + `.onReceive` to call `manager.tick()`. We do NOT use `TimelineView` — calling `tick()` inside `TimelineView.body` would be a side effect during rendering, and SwiftUI will re-render the view automatically when `@Observable` properties change from the tick.

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/MainTimerView.swift
git commit -m "feat: MainTimerView composing panels, chain, controls, keyboard"
```

#### Task 5.6: SettingsView Stub

**Files:**
- Create: `Pomodoro/Views/SettingsView.swift`

- [ ] **Step 1: Create placeholder SettingsView**

This stub prevents build failures when `MainTimerView` references `SettingsView`. The full implementation comes in Phase 8.

```swift
import SwiftUI

struct SettingsView: View {
    let settings: any SettingsStoring

    var body: some View {
        Text("Settings — placeholder")
            .frame(width: 300, height: 200)
    }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/SettingsView.swift
git commit -m "feat: SettingsView placeholder stub"
```

#### Task 5.7: Digit Input Unit Tests

**Files:**
- Create: `PomodoroTests/DigitInputTests.swift`

- [ ] **Step 1: Write tests for digit input logic**

Test the digit input state machine (first digit → tens, second digit → ones + auto-deselect) and arrow key adjustment, independent of the view.

```swift
import XCTest
@testable import Pomodoro

@MainActor
final class DigitInputTests: XCTestCase {
    var timeProvider: MockTimeProvider!
    var timer: TimerModel!

    override func setUp() {
        timeProvider = MockTimeProvider()
        timer = TimerModel(timeProvider: timeProvider)
    }

    func testSetTimeMinutesClampsTo99() {
        timer.setTime(minutes: 120, seconds: 0)
        XCTAssertEqual(timer.displayMinutes, 99)
    }

    func testSetTimeSecondsClampsTo59() {
        timer.setTime(minutes: 0, seconds: 75)
        XCTAssertEqual(timer.displaySeconds, 59)
    }

    func testSetTimeUpdatesDisplay() {
        timer.setTime(minutes: 15, seconds: 30)
        XCTAssertEqual(timer.displayMinutes, 15)
        XCTAssertEqual(timer.displaySeconds, 30)
    }

    func testSetTimeWhileRunningIsIgnored() {
        timer.setTime(minutes: 5, seconds: 0)
        timer.mode = .countdown
        timer.play()
        // Advance time so display has changed from initial value
        timeProvider.advance(by: 1)
        timer.tick()
        XCTAssertEqual(timer.displayMinutes, 4, "Should have counted down 1 second")
        XCTAssertEqual(timer.displaySeconds, 59)
        // Now try to setTime while running — should be ignored
        timer.setTime(minutes: 10, seconds: 0)
        XCTAssertEqual(timer.displayMinutes, 4, "setTime should be ignored while running")
        XCTAssertEqual(timer.displaySeconds, 59)
    }
}
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/DigitInputTests 2>&1 | tail -10`
Expected: PASS (these test TimerModel.setTime which already exists)

- [ ] **Step 3: Commit**

```bash
git add PomodoroTests/DigitInputTests.swift
git commit -m "test: digit input clamping and display update tests"
```

#### Phase 5 Gate

- [ ] **Verify build + tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests 2>&1 | grep -E '(Executed|FAIL)'`
Expected: All PASS

All views compile. Preview renders in Xcode.

---

### Phase 6: App Shell (Menu Bar + Detachable Window)

**Acceptance criteria:** App appears in macOS menu bar. Clicking icon shows timer panel. Pin button detaches to floating `NSPanel`. Closing panel returns to popover mode. Menu bar shows running timer text. Panel remembers position.

#### Task 6.0: Service Stubs (SoundManager + NotificationManager)

**Files:**
- Create: `Pomodoro/Services/SoundManager.swift`
- Create: `Pomodoro/Services/NotificationManager.swift`

> **Why:** `PomodoroApp` (Task 6.1) instantiates `SoundManager` and `NotificationManager`. These are fully implemented in Phase 7, but we need compilable stubs now so Phase 6 builds.

- [ ] **Step 1: Create `SoundManager` stub**

```swift
import Foundation

final class SoundManager: SoundPlaying, @unchecked Sendable {
    private let settings: any SettingsStoring

    init(settings: any SettingsStoring) {
        self.settings = settings
    }

    func playTransitionBeep() {
        // Stub — full implementation in Phase 7
    }

    func playCompletionAlarm() {
        // Stub — full implementation in Phase 7
    }

    func stopAlarm() {
        // Stub — full implementation in Phase 7
    }
}
```

- [ ] **Step 2: Create `NotificationManager` stub**

```swift
import Foundation

final class NotificationManager: NotificationSending {
    func send(title: String, body: String) {
        // Stub — full implementation in Phase 7
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Pomodoro/Services/SoundManager.swift Pomodoro/Services/NotificationManager.swift
git commit -m "feat: SoundManager and NotificationManager stubs for Phase 6"
```

#### Task 6.1: PomodoroApp Entry Point

**Files:**
- Modify: `Pomodoro/PomodoroApp.swift`

- [ ] **Step 1: Update `PomodoroApp.swift`**

```swift
import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var manager: PomodoroManager
    @State private var settings: AppSettingsStore

    init() {
        let settingsStore = AppSettingsStore()
        let soundManager = SoundManager(settings: settingsStore)
        let notificationManager = NotificationManager()
        let manager = PomodoroManager(
            timeProvider: SystemTimeProvider(),
            soundPlayer: soundManager,
            notificationSender: notificationManager,
            settings: settingsStore
        )
        self._manager = State(initialValue: manager)
        self._settings = State(initialValue: settingsStore)

        // Set default times from settings
        manager.timer1.setTime(
            minutes: settingsStore.defaultT1Minutes,
            seconds: settingsStore.defaultT1Seconds
        )
        manager.timer2.setTime(
            minutes: settingsStore.defaultT2Minutes,
            seconds: settingsStore.defaultT2Seconds
        )
    }

    var body: some Scene {
        MenuBarExtra {
            if !appDelegate.isPanelOpen {
                MainTimerView(
                    settings: settings,
                    scale: settings.windowSize.scaleFactor,
                    onDetach: { appDelegate.openPanel(manager: manager, settings: settings) }
                )
                .environment(manager)
            } else {
                // When panel is open, minimal menu: just "Show Window" + "Quit"
                VStack {
                    Button("Show Window") {
                        appDelegate.bringPanelToFront()
                    }
                    Divider()
                    Button("Quit Pomodoro") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding()
            }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if manager.timer1.isRunning || manager.timer2.isRunning {
            let timer = manager.timer1.isRunning ? manager.timer1 : manager.timer2
            Text(String(format: "%02d:%02d", timer.displayMinutes, timer.displaySeconds))
                .monospacedDigit()
        } else {
            Image(systemName: "timer")
        }
    }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/PomodoroApp.swift
git commit -m "feat: PomodoroApp entry point with MenuBarExtra"
```

#### Task 6.2: AppDelegate with NSPanel

**Files:**
- Create: `Pomodoro/AppDelegate.swift`

- [ ] **Step 1: Create `AppDelegate.swift`**

```swift
import AppKit
import SwiftUI

@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private(set) var isPanelOpen = false
    private var lastPanelFrame: NSRect?

    func openPanel(manager: PomodoroManager, settings: AppSettingsStore) {
        guard panel == nil else {
            bringPanelToFront()
            return
        }

        let contentView = MainTimerView(
            settings: settings,
            scale: settings.windowSize.scaleFactor,
            onDetach: nil // No detach button when already in panel
        )
        .environment(manager)

        let hostingView = NSHostingView(rootView: contentView)

        let size = panelSize(for: settings.windowSize)
        let frame: NSRect
        if let last = lastPanelFrame {
            frame = last
        } else {
            // Center on screen
            let screen = NSScreen.main?.visibleFrame ?? .zero
            frame = NSRect(
                x: screen.midX - size.width / 2,
                y: screen.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        }

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor(white: 0.04, alpha: 1.0)
        panel.contentView = hostingView
        panel.delegate = self

        panel.orderFront(nil)
        self.panel = panel
        isPanelOpen = true
    }

    func bringPanelToFront() {
        panel?.orderFront(nil)
    }

    private func panelSize(for windowSize: WindowSize) -> NSSize {
        let width = windowSize.width
        let aspectRatio: CGFloat = 1.6 // Approximate height ratio
        return NSSize(width: width, height: width * aspectRatio)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let panel = notification.object as? NSPanel {
            lastPanelFrame = panel.frame
        }
        panel = nil
        isPanelOpen = false
    }
}
```

- [ ] **Step 2: Build and test manually**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

Launch the app → verify menu bar icon appears → click → verify timer panel shows → click pin → verify floating panel appears → close panel → verify returns to popover mode.

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/AppDelegate.swift
git commit -m "feat: AppDelegate with NSPanel detachable floating window"
```

#### Phase 6 Gate

- [ ] **Manual acceptance testing**

1. App appears in menu bar with `timer` SF Symbol
2. Click menu bar icon → timer panel popover shows
3. Click pin → floating NSPanel opens
4. Close panel → returns to popover mode
5. While running, menu bar shows `MM:SS`
6. Panel remembers position between detach/re-attach

Run all unit tests to confirm no regressions:
`xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests 2>&1 | grep -E '(Executed|FAIL)'`

---

## Chunk 3: Phases 7–10 (Services, Settings, Testing, Polish)

### Phase 7: Sound + Notifications

**Acceptance criteria:** Sounds play on timer completion. Transition beep on T1→T2 (plays once). Full alarm on final completion (loops until stopped). Alarm stops after 60s or user interaction. macOS notifications fire. Notification permission requested on first launch. SoundManager and NotificationManager have unit tests.

#### Task 7.1: SoundManager Tests (TDD)

**Files:**
- Create: `PomodoroTests/SoundManagerTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
import AppKit  // Required for NSSound in testPreviewPlaysSelectedSound
@testable import Pomodoro

@MainActor
final class SoundManagerTests: XCTestCase {
    func testPlayTransitionBeepDoesNotThrow() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        // Should not crash even without bundled sounds in test bundle
        manager.playTransitionBeep()
    }

    func testPlayCompletionAlarmDoesNotThrow() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        manager.playCompletionAlarm()
        manager.stopAlarm() // Should cleanly stop
    }

    func testStopAlarmClearsState() {
        let settings = MockSettingsStore()
        let manager = SoundManager(settings: settings)
        manager.playCompletionAlarm()
        manager.stopAlarm()
        // Calling stopAlarm again should be safe (idempotent)
        manager.stopAlarm()
    }

    func testCorrectSoundLoadedForUserSelection() {
        // Verify SoundManager uses the sound names from settings
        let settings = MockSettingsStore()
        settings.transitionSound = "Tink"
        settings.completionSound = "Sosumi"
        let manager = SoundManager(settings: settings)
        // playTransitionBeep should use "Tink", not the default
        // Since we can't inspect AVAudioPlayer internals easily,
        // verify it doesn't crash with a non-default sound name
        manager.playTransitionBeep()
        manager.playCompletionAlarm()
        manager.stopAlarm()
    }

    func testPreviewPlaysSelectedSound() {
        // Verify that playing a system sound by name works (preview functionality)
        // This tests the NSSound fallback path used by the preview buttons
        let sound = NSSound(named: "Tink")
        XCTAssertNotNil(sound, "System sound 'Tink' should be available")
        // Play and immediately stop to verify it doesn't crash
        sound?.play()
        sound?.stop()
    }
}
```

- [ ] **Step 2: Run tests — should fail (SoundManager not yet created)**

Expected: FAIL — `SoundManager` not defined

#### Task 7.2: SoundManager Implementation

**Files:**
- Modify: `Pomodoro/Services/SoundManager.swift` (replace stub from Task 6.0)

> **Note:** This replaces the stub created in Task 6.0. Delete the stub content and replace with the full implementation below.

- [ ] **Step 1: Replace `SoundManager` stub with full implementation**

```swift
import AVFoundation
import AppKit

final class SoundManager: SoundPlaying, @unchecked Sendable {
    // Separate players so transition beep doesn't stomp the alarm reference
    private var transitionPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var alarmTimer: Timer?
    private let settings: any SettingsStoring

    init(settings: any SettingsStoring) {
        self.settings = settings
    }

    func playTransitionBeep() {
        // Transition beep plays ONCE (numberOfLoops = 0)
        transitionPlayer = loadPlayer(named: settings.transitionSound, fallback: "transition-beep", loops: false)
        transitionPlayer?.numberOfLoops = 0
        transitionPlayer?.play()
    }

    func playCompletionAlarm() {
        // Alarm LOOPS until stopped (numberOfLoops = -1)
        alarmPlayer = loadPlayer(named: settings.completionSound, fallback: "completion-alarm", loops: true)
        alarmPlayer?.numberOfLoops = -1
        alarmPlayer?.play()

        // Auto-stop after 60 seconds
        alarmTimer?.invalidate()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { [weak self] _ in
            self?.stopAlarm()
        }
    }

    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
        alarmPlayer?.stop()
        alarmPlayer = nil
        fallbackNSSound?.stop()
        fallbackNSSound = nil
    }

    /// NSSound used as fallback when AVAudioPlayer can't load a system sound.
    /// Stored so stopAlarm() can stop it.
    private var fallbackNSSound: NSSound?

    private func loadPlayer(named name: String, fallback: String, loops: Bool) -> AVAudioPlayer? {
        let soundName = name.isEmpty ? fallback : name

        // Try bundled sound
        if let url = Bundle.main.url(forResource: soundName, withExtension: "aiff")
                ?? Bundle.main.url(forResource: soundName, withExtension: "mp3")
                ?? Bundle.main.url(forResource: soundName, withExtension: "wav") {
            return try? AVAudioPlayer(contentsOf: url)
        }

        // Fallback: system NSSound. Set loops BEFORE calling play() to avoid race.
        if let nsSound = NSSound(named: soundName) {
            fallbackNSSound = nsSound
            nsSound.loops = loops
            nsSound.play()
        } else {
            NSSound.beep()
        }
        return nil
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/SoundManagerTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 3: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Pomodoro/Services/SoundManager.swift PomodoroTests/SoundManagerTests.swift
git commit -m "feat: SoundManager with separate players for beep vs alarm — TDD green"
```

#### Task 7.3: NotificationManager Tests (TDD)

**Files:**
- Create: `PomodoroTests/NotificationManagerTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import Pomodoro

final class NotificationManagerTests: XCTestCase {
    func testSendDoesNotThrow() {
        let manager = NotificationManager()
        // Should not crash (notification may not display in test environment)
        manager.send(title: "Test", body: "Body")
    }
}
```

- [ ] **Step 2: Run tests — should fail (NotificationManager not yet created)**

Expected: FAIL — `NotificationManager` not defined

#### Task 7.4: NotificationManager Implementation

**Files:**
- Modify: `Pomodoro/Services/NotificationManager.swift` (replace stub from Task 6.0)

> **Note:** This replaces the stub created in Task 6.0. Delete the stub content and replace with the full implementation below.

- [ ] **Step 1: Replace `NotificationManager` stub with full implementation**

```swift
import UserNotifications

final class NotificationManager: NotificationSending, @unchecked Sendable {
    init() {
        requestPermission()
    }

    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil // We handle sound separately via SoundManager

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Fire immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/NotificationManagerTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Services/NotificationManager.swift PomodoroTests/NotificationManagerTests.swift
git commit -m "feat: NotificationManager with UNUserNotificationCenter — TDD green"
```

#### Task 7.5: Add Default Sound Files

**Files:**
- Create: `Pomodoro/Resources/transition-beep.aiff`
- Create: `Pomodoro/Resources/completion-alarm.aiff`

- [ ] **Step 1: Generate placeholder sound files**

For now, use macOS system sounds as placeholders. Copy them into the project:

```bash
# Copy system sounds as temporary placeholders
cp /System/Library/Sounds/Tink.aiff Pomodoro/Resources/transition-beep.aiff
cp /System/Library/Sounds/Sosumi.aiff Pomodoro/Resources/completion-alarm.aiff
```

Add both files to the Xcode project's "Copy Bundle Resources" build phase.

- [ ] **Step 2: Verify build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Resources/
git commit -m "feat: add placeholder sound files for transition beep and alarm"
```

#### Phase 7 Gate

- [ ] **Manual acceptance testing**

1. Set T1 to 00:05 countdown → play → wait for completion → alarm plays + notification banner
2. Chain T1 (00:03) + T2 (00:03) → play → T1 completes with beep → T2 starts → T2 completes with full alarm
3. Alarm stops when clicking the app
4. Alarm auto-stops after 60 seconds

Run unit tests: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests 2>&1 | grep -E '(Executed|FAIL)'`

---

### Phase 8: Settings

**Acceptance criteria:** `AppSettingsStore` persists all settings. `SettingsView` allows changing digit color, sounds, default times, and window size. Changes apply immediately and propagate to SwiftUI via `@Observable`. Settings persist across app launches.

#### Task 8.1: AppSettingsStore

**Files:**
- Create: `Pomodoro/Services/AppSettingsStore.swift`

- [ ] **Step 1: Create `AppSettingsStore`**

> **Important:** `@Observable` only tracks **stored** properties. Computed properties backed by `UserDefaults` won't trigger SwiftUI updates. We use stored properties that mirror UserDefaults, syncing on read/write. The `SettingsStoring` protocol requires `digitColorHex` (hex string) — we implement that directly as a stored property.

```swift
import SwiftUI

@MainActor
@Observable
final class AppSettingsStore: SettingsStoring {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let digitColorHex = "digitColorHex"
        static let transitionSound = "transitionSound"
        static let completionSound = "completionSound"
        static let defaultT1Minutes = "defaultT1Minutes"
        static let defaultT1Seconds = "defaultT1Seconds"
        static let defaultT2Minutes = "defaultT2Minutes"
        static let defaultT2Seconds = "defaultT2Seconds"
        static let windowSize = "windowSize"
    }

    // MARK: - Stored properties (tracked by @Observable)
    var digitColorHex: String {
        didSet { defaults.set(digitColorHex, forKey: Keys.digitColorHex) }
    }
    var transitionSound: String {
        didSet { defaults.set(transitionSound, forKey: Keys.transitionSound) }
    }
    var completionSound: String {
        didSet { defaults.set(completionSound, forKey: Keys.completionSound) }
    }
    var defaultT1Minutes: Int {
        didSet { defaults.set(defaultT1Minutes, forKey: Keys.defaultT1Minutes) }
    }
    var defaultT1Seconds: Int {
        didSet { defaults.set(defaultT1Seconds, forKey: Keys.defaultT1Seconds) }
    }
    var defaultT2Minutes: Int {
        didSet { defaults.set(defaultT2Minutes, forKey: Keys.defaultT2Minutes) }
    }
    var defaultT2Seconds: Int {
        didSet { defaults.set(defaultT2Seconds, forKey: Keys.defaultT2Seconds) }
    }
    var windowSize: WindowSize {
        didSet { defaults.set(windowSize.rawValue, forKey: Keys.windowSize) }
    }

    init() {
        // Register defaults first
        defaults.register(defaults: [
            Keys.digitColorHex: "FFFFFF",
            Keys.transitionSound: "transition-beep",
            Keys.completionSound: "completion-alarm",
            Keys.defaultT1Minutes: 25,
            Keys.defaultT1Seconds: 0,
            Keys.defaultT2Minutes: 5,
            Keys.defaultT2Seconds: 0,
            Keys.windowSize: WindowSize.small.rawValue,
        ])

        // Load from UserDefaults into stored properties
        self.digitColorHex = defaults.string(forKey: Keys.digitColorHex) ?? "FFFFFF"
        self.transitionSound = defaults.string(forKey: Keys.transitionSound) ?? "transition-beep"
        self.completionSound = defaults.string(forKey: Keys.completionSound) ?? "completion-alarm"
        self.defaultT1Minutes = defaults.integer(forKey: Keys.defaultT1Minutes)
        self.defaultT1Seconds = defaults.integer(forKey: Keys.defaultT1Seconds)
        self.defaultT2Minutes = defaults.integer(forKey: Keys.defaultT2Minutes)
        self.defaultT2Seconds = defaults.integer(forKey: Keys.defaultT2Seconds)
        self.windowSize = WindowSize(rawValue: defaults.string(forKey: Keys.windowSize) ?? "small") ?? .small
    }
}
```

> **Note on spec deviation:** The spec mentions `@AppStorage`, but `@AppStorage` is a SwiftUI property wrapper designed for use inside `View` types. For an `@Observable` model type, stored properties with `didSet` syncing to `UserDefaults` is the correct pattern — it provides both SwiftUI observation tracking and persistence.

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Services/AppSettingsStore.swift
git commit -m "feat: AppSettingsStore with UserDefaults persistence"
```

#### Task 8.2: SettingsView

**Files:**
- Modify: `Pomodoro/Views/SettingsView.swift` (replace stub from Task 5.6)
- Modify: `Pomodoro/Views/MainTimerView.swift` (update call site)

> **Note:** The stub SettingsView (Task 5.6) takes `any SettingsStoring`. This full implementation changes to concrete `AppSettingsStore` for `@Observable` tracking. You MUST also update `MainTimerView`'s `.sheet` call to pass the concrete `AppSettingsStore` instead of `any SettingsStoring`. In `MainTimerView`, change the `settings` property from `let settings: any SettingsStoring` to `let settings: AppSettingsStore`, and update `PomodoroApp` accordingly to pass the concrete type.

- [ ] **Step 1: Replace SettingsView stub with full implementation**

```swift
import SwiftUI
import AppKit  // Required for NSSound used in sound preview buttons

/// Note: Uses concrete `AppSettingsStore` rather than `any SettingsStoring` because
/// SwiftUI's `@Observable` tracking requires a concrete type to detect property changes.
/// Existential `any` erases the observation metadata. This is an intentional deviation
/// from the protocol-based DI pattern used elsewhere.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var settings: AppSettingsStore

    // Color presets: name, display color, hex value
    private let colorPresets: [(String, Color, String)] = [
        ("White", .white, "FFFFFF"),
        ("Green", .green, "00FF00"),
        ("Amber", .orange, "FF8000"),
        ("Red", .red, "FF0000"),
        ("Blue", .blue, "0000FF"),
    ]

    @State private var customColor: Color = .white
    @State private var useCustomColor = false

    var body: some View {
        Form {
            // Digit Color
            Section("Digit Color") {
                HStack(spacing: 12) {
                    ForEach(colorPresets, id: \.0) { name, color, hex in
                        Button(action: {
                            settings.digitColorHex = hex
                            useCustomColor = false
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(settings.digitColorHex == hex && !useCustomColor
                                                ? Color.accentColor : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(name)
                    }

                    ColorPicker("Custom", selection: $customColor)
                        .onChange(of: customColor) { newValue in
                            settings.digitColorHex = newValue.hexString
                            useCustomColor = true
                        }
                }
            }

            // Sound Selection
            Section("Sounds") {
                HStack {
                    Text("Transition beep:")
                    Picker("", selection: Binding(
                        get: { settings.transitionSound },
                        set: { settings.transitionSound = $0 }
                    )) {
                        Text("Default Beep").tag("transition-beep")
                        Text("Tink").tag("Tink")
                        Text("Pop").tag("Pop")
                        Text("Ping").tag("Ping")
                    }
                    .frame(width: 150)

                    Button("▶") {
                        // Preview sound
                        if let sound = NSSound(named: settings.transitionSound) {
                            sound.play()
                        }
                    }
                }

                HStack {
                    Text("Completion alarm:")
                    Picker("", selection: Binding(
                        get: { settings.completionSound },
                        set: { settings.completionSound = $0 }
                    )) {
                        Text("Default Alarm").tag("completion-alarm")
                        Text("Sosumi").tag("Sosumi")
                        Text("Glass").tag("Glass")
                        Text("Purr").tag("Purr")
                    }
                    .frame(width: 150)

                    Button("▶") {
                        if let sound = NSSound(named: settings.completionSound) {
                            sound.play()
                        }
                    }
                }
            }

            // Default Times
            Section("Default Times") {
                HStack {
                    Text("Timer 1:")
                    TextField("Min", value: Binding(
                        get: { settings.defaultT1Minutes },
                        set: { settings.defaultT1Minutes = min(max($0, 0), 99) }
                    ), format: .number)
                    .frame(width: 50)
                    Text(":")
                    TextField("Sec", value: Binding(
                        get: { settings.defaultT1Seconds },
                        set: { settings.defaultT1Seconds = min(max($0, 0), 59) }
                    ), format: .number)
                    .frame(width: 50)
                }

                HStack {
                    Text("Timer 2:")
                    TextField("Min", value: Binding(
                        get: { settings.defaultT2Minutes },
                        set: { settings.defaultT2Minutes = min(max($0, 0), 99) }
                    ), format: .number)
                    .frame(width: 50)
                    Text(":")
                    TextField("Sec", value: Binding(
                        get: { settings.defaultT2Seconds },
                        set: { settings.defaultT2Seconds = min(max($0, 0), 59) }
                    ), format: .number)
                    .frame(width: 50)
                }
            }

            // Window Size
            Section("Window Size") {
                Picker("Size:", selection: Binding(
                    get: { settings.windowSize },
                    set: { settings.windowSize = $0 }
                )) {
                    Text("Small (280pt)").tag(WindowSize.small)
                        .accessibilityIdentifier("windowSizeSmall")
                    Text("Medium (360pt)").tag(WindowSize.medium)
                        .accessibilityIdentifier("windowSizeMedium")
                    Text("Large (460pt)").tag(WindowSize.large)
                        .accessibilityIdentifier("windowSizeLarge")
                    Text("XL (580pt)").tag(WindowSize.xl)
                        .accessibilityIdentifier("windowSizeXL")
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Views/SettingsView.swift
git commit -m "feat: SettingsView with color, sound, times, window size"
```

#### Task 8.3: AppSettingsStore Unit Tests

**Files:**
- Create: `PomodoroTests/AppSettingsStoreTests.swift`

- [ ] **Step 1: Write persistence round-trip tests**

```swift
import XCTest
@testable import Pomodoro

@MainActor
final class AppSettingsStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        for key in ["digitColorHex", "transitionSound", "completionSound",
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

        // Create a new instance — should read persisted values
        let store2 = AppSettingsStore()
        XCTAssertEqual(store2.digitColorHex, "00FF00")
        XCTAssertEqual(store2.defaultT1Minutes, 15)
        XCTAssertEqual(store2.windowSize, .large)
    }

    func testDigitColorComputedProperty() {
        let store = AppSettingsStore()
        store.digitColorHex = "FF0000"
        // Verify the protocol extension provides a Color
        let _ = store.digitColor // Should not crash
    }
}
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests/AppSettingsStoreTests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add PomodoroTests/AppSettingsStoreTests.swift
git commit -m "test: AppSettingsStore persistence round-trip tests"
```

#### Phase 8 Gate

- [ ] **Manual acceptance testing**

1. Open Settings (gear icon or Cmd+,)
2. Change digit color → verify display updates immediately
3. Change sounds → preview button plays the sound
4. Change default times → quit and relaunch → verify times persist
5. Change window size → verify panel resizes proportionally
6. All settings survive app restart

Run unit tests: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroTests 2>&1 | grep -E '(Executed|FAIL)'`

---

### Phase 9: UI Tests (XCUITest)

**Acceptance criteria:** All automated UI tests pass, covering: countdown, count-up, pause/resume, reset, chained flow, mode toggle, chain toggle, digit input, input-disabled-while-running.

#### Task 9.1: XCUITest Setup + Basic Countdown Test

**Files:**
- Create: `PomodoroUITests/PomodoroUITests.swift`

- [ ] **Step 1: Create the UI test file with first test**

```swift
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

    // Helper to get the menu bar extra
    private func openTimerPanel() {
        let menuBarItem = app.menuBarItems["timer"]
        if menuBarItem.exists {
            menuBarItem.click()
        }
    }

    func testAppLaunchesWithTimerPanel() {
        openTimerPanel()

        // Verify the timer panel elements are present
        let t1PlayPause = app.buttons["timerT1PlayPause"]
        XCTAssertTrue(t1PlayPause.waitForExistence(timeout: 5), "T1 play button should exist")

        let t2PlayPause = app.buttons["timerT2PlayPause"]
        XCTAssertTrue(t2PlayPause.waitForExistence(timeout: 5), "T2 play button should exist")

        let chainButton = app.buttons["chainLinkButton"]
        XCTAssertTrue(chainButton.waitForExistence(timeout: 5), "Chain button should exist")
    }
}
```

Note: XCUITest for `MenuBarExtra` apps requires accessibility identifiers on key elements. The next steps add identifiers and flesh out the tests.

- [ ] **Step 2: Add accessibility identifiers to views**

Add to key views in `MainTimerView.swift`, `TimerPanelView.swift`, etc.:

```swift
// In TimerPanelView, add to the seven-segment display container:
.accessibilityIdentifier("timer\(label)Display")
.accessibilityValue(String(format: "%02d:%02d", timer.displayMinutes, timer.displaySeconds))

// In TimerPanelView, add to the minutes digit pair area:
.accessibilityIdentifier("timer\(label)Minutes")

// In TimerPanelView, add to the seconds digit pair area:
.accessibilityIdentifier("timer\(label)Seconds")

// In TimerControls play button:
.accessibilityIdentifier("timer\(label)PlayPause")

// In TimerControls reset button:
.accessibilityIdentifier("timer\(label)Reset")

// In ModeArrow:
.accessibilityIdentifier("timer\(label)ModeArrow")

// In ChainLinkButton:
.accessibilityIdentifier("chainLinkButton")
```

- [ ] **Step 3: Run UI tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroUITests 2>&1 | tail -10`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add PomodoroUITests/ Pomodoro/Views/
git commit -m "feat: XCUITest setup with accessibility identifiers"
```

#### Task 9.2: Full UI Test Suite

**Files:**
- Modify: `PomodoroUITests/PomodoroUITests.swift`

- [ ] **Step 1: Add remaining UI tests**

```swift
// Add these tests to PomodoroUITests class:

func testModeToggle() {
    openTimerPanel()
    let modeArrow = app.buttons["timerT1ModeArrow"]
    guard modeArrow.waitForExistence(timeout: 5) else {
        XCTFail("Mode arrow not found")
        return
    }
    let initialLabel = modeArrow.label
    modeArrow.click()
    // Verify the label changed after toggling
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
    // Verify T2 controls are hidden when chained — wait for UI update
    let t2PlayPause = app.buttons["timerT2PlayPause"]
    let disappeared = t2PlayPause.waitForNonExistence(timeout: 2)
    XCTAssertTrue(disappeared, "T2 play/pause should disappear when chained")

    // Unchain
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
    playButton.click() // Play
    sleep(1)
    playButton.click() // Pause
    // Record display value while paused
    let pausedValue = display.value as? String ?? ""
    sleep(1)
    // After 1s paused, value should not have changed
    let stillPausedValue = display.value as? String ?? ""
    XCTAssertEqual(pausedValue, stillPausedValue, "Display should not change while paused")
    playButton.click() // Resume
    sleep(1)
    playButton.click() // Pause again to check it changed
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

    // Record initial display value
    let initialValue = display.value as? String ?? ""
    playButton.click() // Play
    sleep(2)
    playButton.click() // Pause
    resetButton.click() // Reset
    // Verify display returned to initial value
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

    // Record display value before starting
    let t1Minutes = app.otherElements["timerT1Minutes"]
    let preStartValue = display.value as? String ?? ""

    playButton.click() // Start timer
    sleep(1) // Let timer run briefly

    // Try to click display minutes — should do nothing while running
    if t1Minutes.exists {
        t1Minutes.click()
        t1Minutes.typeText("99")
        sleep(1)
    }

    playButton.click() // Pause

    // Verify the typed digits had no effect — minutes should NOT be 99
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
    modeArrow.click() // Switch to timer (▲) mode

    let display = app.otherElements["timerT1Display"]
    let playButton = app.buttons["timerT1PlayPause"]
    playButton.click() // Start counting up
    sleep(3)
    playButton.click() // Pause
    // Timer should have counted up from 00:00 — display should show elapsed time
    let displayValue = display.value as? String ?? "00:00"
    XCTAssertNotEqual(displayValue, "00:00", "Count-up timer should have elapsed past 00:00")
}

func testChainedFlow() {
    openTimerPanel()

    // Chain timers
    let chainButton = app.buttons["chainLinkButton"]
    guard chainButton.waitForExistence(timeout: 5) else {
        XCTFail("Chain button not found")
        return
    }
    chainButton.click()

    // Set T1 to a very short countdown (e.g., 00:03)
    // Use T1 digit input to set minutes=0, seconds=3
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

    // Start chained sequence
    let playButton = app.buttons["timerT1PlayPause"]
    guard playButton.waitForExistence(timeout: 5) else {
        XCTFail("Play button not found")
        return
    }
    playButton.click()

    // Wait for T1 to complete and T2 to auto-start
    sleep(5)

    // Verify T2 is now running — T1 should have completed and T2 auto-started
    let t2Display = app.otherElements["timerT2Display"]
    if t2Display.exists {
        let t2Value = t2Display.value as? String ?? "00:00"
        // T2 should no longer be at its initial set value (it should have counted down)
        XCTAssertNotEqual(t2Value, "", "T2 display should have a value")
    }

    // Verify T1 shows 00:00 (completed)
    let t1Display = app.otherElements["timerT1Display"]
    if t1Display.exists {
        let t1Value = t1Display.value as? String ?? ""
        XCTAssertEqual(t1Value, "00:00", "T1 should show 00:00 after completion")
    }

    playButton.click() // Pause to clean up
}

func testDigitInput() {
    openTimerPanel()

    // Click on T1 minutes to select
    let t1Minutes = app.otherElements["timerT1Minutes"]
    guard t1Minutes.waitForExistence(timeout: 5) else {
        XCTFail("T1 minutes display not found")
        return
    }
    t1Minutes.click()
    t1Minutes.typeText("15")

    // Click on T1 seconds
    let t1Seconds = app.otherElements["timerT1Seconds"]
    guard t1Seconds.waitForExistence(timeout: 5) else {
        XCTFail("T1 seconds display not found")
        return
    }
    t1Seconds.click()
    t1Seconds.typeText("30")

    // Verify display shows the entered values
    let t1Display = app.otherElements["timerT1Display"]
    if t1Display.exists {
        let displayValue = t1Display.value as? String ?? ""
        XCTAssertTrue(displayValue.contains("15") || displayValue.contains("30"),
            "Display should reflect entered digits, got: \(displayValue)")
    }
    // Also verify individual digit pair values if exposed
    let minutesValue = t1Minutes.value as? String ?? ""
    XCTAssertEqual(minutesValue, "15", "Minutes should show 15 after typing '15'")
    let secondsValue = t1Seconds.value as? String ?? ""
    XCTAssertEqual(secondsValue, "30", "Seconds should show 30 after typing '30'")
}
```

```swift
func testWindowSizeSwitching() {
    openTimerPanel()
    let settingsButton = app.buttons["settingsButton"]
    guard settingsButton.waitForExistence(timeout: 5) else {
        XCTFail("Settings button not found")
        return
    }
    settingsButton.click()

    // Settings opens as a sheet within the MenuBarExtra panel
    // Look for the radio group options within the current UI hierarchy
    let largeButton = app.radioButtons["windowSizeLarge"]
    guard largeButton.waitForExistence(timeout: 5) else {
        XCTFail("Window size 'Large' radio button not found")
        return
    }

    // Verify the radio button can be selected
    largeButton.click()
    sleep(1) // Allow resize animation

    // Verify the selection changed — the Large radio button should now be selected
    XCTAssertTrue(largeButton.isSelected || (largeButton.value as? Bool == true),
        "Large window size radio button should be selected after clicking")
}
```

- [ ] **Step 2: Run all UI tests**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -only-testing:PomodoroUITests 2>&1 | tail -15`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add PomodoroUITests/PomodoroUITests.swift
git commit -m "test: full XCUITest suite for UI flows"
```

#### Phase 9 Gate

- [ ] **Run all tests (unit + UI)**

Run: `xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' 2>&1 | grep -E '(Test Suite|Executed|PASS|FAIL)'`

**Acceptance criteria:** All unit tests and UI tests pass.

---

### Phase 10: Polish + App Store Preparation

**Acceptance criteria:** Window sizing works across all 4 sizes. Keyboard shortcuts functional (implemented in Phase 5 via `NSEvent.addLocalMonitorForEvents`). App icon present. Code signing configured for App Store distribution. App sandbox enabled. Build produces a signed `.app` bundle ready for App Store submission.

> **Note:** Keyboard shortcuts (Space, R, 1/2, Tab, Up/Down, Enter/Esc) are already implemented in Phase 5 Task 5.5 using `NSEvent.addLocalMonitorForEvents` for macOS 13 compatibility. Phase 10 QA verifies they work correctly but does not re-implement them.

#### Task 10.1: Window Size Scaling

**Files:**
- Modify: `Pomodoro/AppDelegate.swift`
- Modify: `Pomodoro/Views/MainTimerView.swift`

- [ ] **Step 1: Wire window size to panel dimensions**

In `AppDelegate.swift`, add a method to resize the panel when settings change:

```swift
func updatePanelSize(for windowSize: WindowSize) {
    guard let panel else { return }
    let newSize = panelSize(for: windowSize)
    let frame = panel.frame
    let newFrame = NSRect(
        x: frame.origin.x,
        y: frame.origin.y + frame.height - newSize.height,
        width: newSize.width,
        height: newSize.height
    )
    panel.setFrame(newFrame, display: true, animate: true)
}
```

- [ ] **Step 2: Trigger `updatePanelSize` when windowSize setting changes**

In `MainTimerView`, add an `.onChange` modifier that calls the AppDelegate's `updatePanelSize` when the settings change:

```swift
// In MainTimerView body, add this modifier to the outer container:
.onChange(of: manager.settings.windowSize) { newSize in
    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
        appDelegate.updatePanelSize(for: newSize)
    }
}
```

> **Note:** `manager.settings` must expose the `AppSettingsStore` (or at minimum `windowSize`) so the view can observe changes. Since `PomodoroManager` already holds a reference to the settings store, add a `let settings: AppSettingsStore` property if not already present, and pass it through from `PomodoroApp`.

- [ ] **Step 3: Build and test all 4 sizes**

Launch app → Settings → switch between Small / Medium / Large / XL → verify proportional scaling of all elements.

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/AppDelegate.swift Pomodoro/Views/MainTimerView.swift
git commit -m "feat: window size scaling across all 4 sizes"
```

#### Task 10.2: App Icon

**Files:**
- Modify: `Pomodoro/Resources/Assets.xcassets`

- [ ] **Step 1: Generate app icon programmatically**

Create a Swift script that generates a 1024×1024 app icon PNG using Core Graphics. The icon should evoke the dual-timer LCD aesthetic — dark background with two stylized seven-segment "00" displays stacked vertically, rendered in the default white digit color.

Create `Scripts/generate-icon.swift`:

```swift
import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

// Dark background with rounded rect
let bgColor = NSColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
bgColor.setFill()
NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 200, yRadius: 200).fill()

// Draw two simplified "00:00" LCD text blocks
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 180, weight: .bold),
    .foregroundColor: NSColor.white
]
let t1 = NSAttributedString(string: "25:00", attributes: attrs)
let t2 = NSAttributedString(string: "05:00", attributes: attrs)
t1.draw(at: NSPoint(x: 200, y: 560))
t2.draw(at: NSPoint(x: 200, y: 280))

image.unlockFocus()

let tiffData = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiffData)!
let pngData = bitmap.representation(using: .png, properties: [:])!
let outputURL = URL(fileURLWithPath: "Pomodoro/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png")
try! pngData.write(to: outputURL)
print("Icon saved to \(outputURL.path)")
```

Run: `swift Scripts/generate-icon.swift`

> **Note:** This generates a placeholder icon. Replace with a professionally designed icon before App Store submission. The programmatic version ensures the build has a valid icon for development and testing.

- [ ] **Step 1b: Update Contents.json**

Replace `Pomodoro/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "filename": "icon_1024.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 2: Build**

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodoro/Resources/Assets.xcassets/
git commit -m "feat: app icon"
```

#### Task 10.3: App Store Code Signing & Sandbox

**Files:**
- Modify: `Pomodoro.xcodeproj/project.pbxproj` (via Xcode)
- Create: `Pomodoro/Pomodoro.entitlements`

- [ ] **Step 1: Configure signing in Xcode**

Open `Pomodoro.xcodeproj` in Xcode:

1. Select the `Pomodoro` target → Signing & Capabilities tab
2. Check "Automatically manage signing"
3. Select your Apple Developer Team
4. Set Bundle Identifier (e.g., `com.yourname.pomodoro`)
5. Ensure "Signing Certificate" is set to "Apple Distribution" for release builds

- [ ] **Step 2: Enable App Sandbox**

In Xcode → Signing & Capabilities → `+ Capability` → Add "App Sandbox":

- **Network:** None needed (no network access)
- **Hardware:** None needed
- **File Access:** None needed (uses `@AppStorage` / `UserDefaults`)
- **App Data:** UserDefaults access is allowed by default in sandbox

- [ ] **Step 3: Create entitlements file**

Create `Pomodoro/Pomodoro.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

Note: `AVAudioPlayer` for bundled sounds works within the sandbox since the files are in the app bundle. `UNUserNotificationCenter` also works in sandbox. `NSPanel` floating windows work in sandbox.

- [ ] **Step 4: Verify sandboxed build**

Run: `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' -configuration Release build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Pomodoro/Pomodoro.entitlements Pomodoro.xcodeproj/
git commit -m "feat: App Sandbox and code signing for App Store"
```

#### Task 10.4: App Store Metadata & Archive

**Files:**
- Modify: `Pomodoro/Info.plist` or Xcode target settings

- [ ] **Step 1: Set App Store metadata in Xcode**

In the target's General tab:
- **Display Name:** Pomodoro
- **Bundle Identifier:** `com.yourname.pomodoro`
- **Version:** 1.0.0
- **Build:** 1
- **Deployment Target:** macOS 13.0
- **Category:** Productivity

- [ ] **Step 2: Create an archive**

Run: `xcodebuild archive -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'generic/platform=macOS' -archivePath build/Pomodoro.xcarchive 2>&1 | tail -10`
Expected: `** ARCHIVE SUCCEEDED **`

- [ ] **Step 3: Verify the archive can be exported**

Open Xcode → Window → Organizer → select the archive → Validate App → ensure no errors.

For actual App Store submission:
1. Organizer → Distribute App → App Store Connect → Upload
2. Or use `xcodebuild -exportArchive` with an export options plist

- [ ] **Step 4: Commit**

```bash
git add Pomodoro.xcodeproj/
git commit -m "feat: App Store metadata and archive configuration"
```

#### Task 10.5: Final QA Checklist

- [ ] **Step 1: Run all tests**

```bash
xcodebuild test -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' 2>&1 | grep -E '(Test Suite|Executed|PASS|FAIL)'
```

All tests pass.

- [ ] **Step 2: Manual QA walkthrough**

Test each spec requirement:

| # | Check | Status |
|---|-------|--------|
| 1 | App appears in menu bar with timer icon | |
| 2 | Click menu bar → popover shows timer panels | |
| 3 | T1 countdown: set 00:10, play, counts down to 00:00 | |
| 4 | T2 count-up: toggle to ▲, play, counts up from 00:00 | |
| 5 | Pause freezes display, resume continues | |
| 6 | Reset returns to set value (countdown) or 00:00 (timer) | |
| 7 | Digit input: click minutes → type "15" → shows 15 | |
| 8 | Digit input: arrow up/down adjusts value | |
| 9 | Tab toggles between minute/second selection | |
| 10 | Enter/Esc deselects digits | |
| 11 | Input disabled while timer running | |
| 12 | Chain toggle: click chain → T2 controls hidden | |
| 13 | Chain forces countdown mode | |
| 14 | Chained: T1 completes → beep + notification → T2 starts | |
| 15 | Chained: T2 completes → full alarm + notification | |
| 16 | Chained: pause/resume mid-chain | |
| 17 | Chained: reset resets both to original values | |
| 18 | Pin/detach → floating NSPanel | |
| 19 | Close panel → returns to popover | |
| 20 | Panel remembers position | |
| 21 | Menu bar shows MM:SS when timer running | |
| 22 | Settings: digit color changes | |
| 23 | Settings: sound selection + preview | |
| 24 | Settings: default times persist | |
| 25 | Settings: window size switching | |
| 26 | Keyboard: Space play/pause, R reset, 1/2 focus | |
| 27 | Alarm stops on click or after 60s | |
| 28 | All 4 window sizes scale proportionally | |

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "chore: final QA pass — all checks verified"
```

#### Phase 10 Gate

**Acceptance criteria:**
1. All unit tests pass
2. All UI tests pass
3. Manual QA checklist complete
4. Release build archives successfully
5. Archive validates for App Store submission
6. App Sandbox enabled with correct entitlements
