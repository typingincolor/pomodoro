import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var settings: AppSettingsStore

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
