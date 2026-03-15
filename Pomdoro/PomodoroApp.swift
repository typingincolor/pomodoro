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
                VStack {
                    Button("Show Window") {
                        appDelegate.bringPanelToFront()
                    }
                    Divider()
                    Button("Quit Pomdoro") {
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
