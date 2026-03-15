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
        guard !isRunning else { return }
        let clampedMinutes = min(max(minutes, 0), 99)
        let clampedSeconds = min(max(seconds, 0), 59)
        targetSeconds = clampedMinutes * 60 + clampedSeconds
        displayMinutes = clampedMinutes
        displaySeconds = clampedSeconds
    }

    func play() {
        guard !isRunning else { return }
        if mode == .countdown && targetSeconds == 0 && elapsedAtPause == 0 {
            return
        }
        startDate = timeProvider.now
        isRunning = true
    }

    func pause() {
        guard isRunning, let startDate else { return }
        elapsedAtPause += timeProvider.now.timeIntervalSince(startDate)
        self.startDate = nil
        isRunning = false
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

    var isCompleted: Bool {
        mode == .countdown && displayMinutes == 0 && displaySeconds == 0 && hasNotifiedCompletion
    }
}
