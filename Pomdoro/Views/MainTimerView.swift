import SwiftUI

struct MainTimerView: View {
    @Environment(PomodoroManager.self) private var manager
    @Environment(\.colorScheme) private var colorScheme

    let settings: AppSettingsStore
    let scale: CGFloat
    let onDetach: (() -> Void)?

    @State private var focusedTimer: Int = 1
    @State private var showSettings = false
    @State private var editingTimerField: TimerField?
    @State private var editingPendingDigit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                TimerPanelView(
                    timer: manager.timer1,
                    label: "T1",
                    color: settings.digitColor,
                    scale: scale,
                    isFocused: focusedTimer == 1,
                    showControls: true,
                    isAlarmPlaying: manager.isAlarmPlaying,
                    onPlay: { manager.isChained ? manager.playChained() : manager.playTimer1() },
                    onPause: { manager.isChained ? manager.pauseChained() : manager.pauseTimer1() },
                    onReset: { manager.isChained ? manager.resetChained() : manager.resetTimer1() },
                    onToggleMode: {
                        guard !manager.isChained else { return }
                        manager.timer1.mode = manager.timer1.mode == .countdown ? .countUp : .countdown
                    },
                    onStopAlarm: { manager.stopAlarm() },
                    selectedField: focusedTimer == 1 ? $editingTimerField : .constant(nil),
                    pendingDigit: focusedTimer == 1 ? $editingPendingDigit : .constant(nil)
                )

                HStack {
                    Spacer()
                    ChainLinkButton(
                        isChained: manager.isChained,
                        scale: scale,
                        action: { manager.toggleChain() }
                    )
                    Spacer()
                }
                .padding(.vertical, 6 * scale)

                TimerPanelView(
                    timer: manager.timer2,
                    label: "T2",
                    color: settings.digitColor,
                    scale: scale,
                    isFocused: focusedTimer == 2,
                    showControls: !manager.isChained,
                    isAlarmPlaying: manager.isAlarmPlaying,
                    onPlay: { manager.playTimer2() },
                    onPause: { manager.pauseTimer2() },
                    onReset: { manager.resetTimer2() },
                    onToggleMode: {
                        guard !manager.isChained else { return }
                        manager.timer2.mode = manager.timer2.mode == .countdown ? .countUp : .countdown
                    },
                    onStopAlarm: { manager.stopAlarm() },
                    selectedField: focusedTimer == 2 ? $editingTimerField : .constant(nil),
                    pendingDigit: focusedTimer == 2 ? $editingPendingDigit : .constant(nil)
                )

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
        .onChange(of: settings.windowSize) { newSize in
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.updatePanelSize(for: newSize)
            }
        }
    }

    @State private var keyMonitor: Any?

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let chars = event.characters else { return false }

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

        return handleDigitEditingKey(event, timer: focusedTimerModel)
    }

    private func handleDigitEditingKey(_ event: NSEvent, timer: TimerModel) -> Bool {
        guard !timer.isRunning else { return false }
        guard editingTimerField != nil else { return false }

        let keyCode = event.keyCode
        guard let chars = event.characters else { return false }

        if keyCode == 126 {
            if editingTimerField == .minutes {
                timer.setTime(minutes: timer.displayMinutes + 1, seconds: timer.displaySeconds)
            } else {
                timer.setTime(minutes: timer.displayMinutes, seconds: timer.displaySeconds + 1)
            }
            return true
        }
        if keyCode == 125 {
            if editingTimerField == .minutes {
                timer.setTime(minutes: max(0, timer.displayMinutes - 1), seconds: timer.displaySeconds)
            } else {
                timer.setTime(minutes: timer.displayMinutes, seconds: max(0, timer.displaySeconds - 1))
            }
            return true
        }
        if keyCode == 48 {
            editingTimerField = (editingTimerField == .minutes) ? .seconds : .minutes
            editingPendingDigit = nil
            return true
        }
        if keyCode == 36 || keyCode == 53 {
            editingTimerField = nil
            editingPendingDigit = nil
            return true
        }
        if let char = chars.first, char.isNumber, let digit = Int(String(char)) {
            if let pending = editingPendingDigit {
                let value = pending * 10 + digit
                if editingTimerField == .minutes {
                    timer.setTime(minutes: value, seconds: timer.displaySeconds)
                } else {
                    timer.setTime(minutes: timer.displayMinutes, seconds: value)
                }
                editingPendingDigit = nil
                editingTimerField = nil
            } else {
                editingPendingDigit = digit
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
