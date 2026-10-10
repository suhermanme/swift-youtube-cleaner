import AppKit
import SwiftUI
import YouTubeCleanerCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("Automation backend") {
                HStack {
                    TextField("Python project", text: $model.backendProjectPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Choose…") { chooseBackendFolder() }
                }
                Label(
                    model.backend.validationMessage,
                    systemImage: model.backend.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(model.backend.isValid ? .green : .orange)
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

    private func chooseBackendFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose the YouTube Cleaner Python project"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = model.backend.projectDirectory
        if panel.runModal() == .OK, let url = panel.url {
            model.backendProjectPath = url.path
        }
    }
}
