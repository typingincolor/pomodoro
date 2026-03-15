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
            onDetach: nil
        )
        .environment(manager)

        let hostingView = NSHostingView(rootView: contentView)

        let size = panelSize(for: settings.windowSize)
        let frame: NSRect
        if let last = lastPanelFrame {
            frame = last
        } else {
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

    private func panelSize(for windowSize: WindowSize) -> NSSize {
        let width = windowSize.width
        let aspectRatio: CGFloat = 1.6
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
