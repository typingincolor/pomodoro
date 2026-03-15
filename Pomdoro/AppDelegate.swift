import AppKit
import SwiftUI

@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func openSettings(settings: AppSettingsStore) {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.orderFront(nil)
            return
        }

        let settingsView = SettingsView(settings: settings, onDone: { [weak self] in
            self?.settingsWindow?.close()
        })

        let hostingView = NSHostingView(rootView: settingsView)
        let settingsPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        settingsPanel.title = "Settings"
        settingsPanel.level = .floating
        settingsPanel.isFloatingPanel = true
        settingsPanel.hidesOnDeactivate = false
        settingsPanel.contentView = hostingView
        settingsPanel.center()
        settingsPanel.orderFront(nil)
        self.settingsWindow = settingsPanel
    }
}
