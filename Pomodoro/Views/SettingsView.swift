import SwiftUI

struct SettingsView: View {
    var settings: AppSettingsStore
    var onDone: (() -> Void)?

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
        VStack(alignment: .leading, spacing: 20) {
            section("Digit Color") {
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

            section("Default Times") {
                HStack(spacing: 16) {
                    timerRow("Timer 1:",
                             minutes: Binding(
                                get: { settings.defaultT1Minutes },
                                set: { settings.defaultT1Minutes = min(max($0, 0), 99) }
                             ),
                             seconds: Binding(
                                get: { settings.defaultT1Seconds },
                                set: { settings.defaultT1Seconds = min(max($0, 0), 59) }
                             ))

                    timerRow("Timer 2:",
                             minutes: Binding(
                                get: { settings.defaultT2Minutes },
                                set: { settings.defaultT2Minutes = min(max($0, 0), 99) }
                             ),
                             seconds: Binding(
                                get: { settings.defaultT2Seconds },
                                set: { settings.defaultT2Seconds = min(max($0, 0), 59) }
                             ))
                }
            }

            section("Window Size") {
                Picker("", selection: Binding(
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
                .labelsHidden()
            }

            Spacer()

            HStack {
                Spacer()
                Button("OK") { onDone?() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380, height: 420)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    @ViewBuilder
    private func timerRow(_ label: String, minutes: Binding<Int>, seconds: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(.secondary)
            TextField("", value: minutes, format: .number)
                .frame(width: 36)
                .textFieldStyle(.roundedBorder)
            Text(":")
            TextField("", value: seconds, format: .number.precision(.integerLength(2)))
                .frame(width: 36)
                .textFieldStyle(.roundedBorder)
        }
    }
}
