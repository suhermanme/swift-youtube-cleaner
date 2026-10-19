import SwiftUI
import YouTubeCleanerCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("Automation backend") {
                Label(
                    model.backend.validationMessage,
                    systemImage: model.backend.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(model.backend.isValid ? .green : .orange)
                Text("The worker, Python runtime, packages, and Chromium are included in this app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Browser") {
                Picker("Default browser", selection: $model.browser) {
                    ForEach(BrowserChoice.allCases) { browser in
                        Text(browser.displayName).tag(browser)
                    }
                }
                Slider(value: $model.delay, in: 0.25...5, step: 0.25) {
                    Text("Action delay")
                } minimumValueLabel: {
                    Text("0.25s")
                } maximumValueLabel: {
                    Text("5s")
                }
                Text("Action delay: \(model.delay, specifier: "%.2f") seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Capture debug diagnostics when automation fails", isOn: $model.debugMode)
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }

}
