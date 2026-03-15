import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let bgColor = NSColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
bgColor.setFill()
NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 200, yRadius: 200).fill()

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
