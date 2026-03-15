import AppKit
import ScreenCaptureKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@main
struct CaptureScreenshot {
    static func main() {
        let script = """
        tell application "System Events"
            tell process "Pomodoro"
                click menu bar item 1 of menu bar 2
            end tell
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        Thread.sleep(forTimeInterval: 1.5)

        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let window = content.windows.first(where: {
                    $0.owningApplication?.bundleIdentifier == "com.pomodoro.Pomodoro" && $0.frame.height > 100
                }) else {
                    print("ERROR: Pomodoro window not found")
                    semaphore.signal()
                    return
                }

                let filter = SCContentFilter(desktopIndependentWindow: window)
                let config = SCStreamConfiguration()
                config.width = Int(window.frame.width) * 2
                config.height = Int(window.frame.height) * 2
                config.showsCursor = false
                config.captureResolution = .best

                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

                let url = URL(fileURLWithPath: "/Users/andrew/Development/pomodoro/docs/screenshot.png")
                let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
                print("OK: saved docs/screenshot.png (\(image.width)x\(image.height))")
            } catch {
                print("ERROR: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
    }
}
