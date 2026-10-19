import SwiftUI
import YouTubeCleanerCore

struct DiagnosticsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Diagnostics & profile")
                        .font(.largeTitle.bold())
                    Text("Read-only inspection and dedicated-browser maintenance.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                GroupBox("Page inspection") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Area", selection: $model.selectedArea) {
                            ForEach(LibraryArea.allCases) { area in
                                Text(area.displayName).tag(area)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            DiagnosticButton("Inspect page", icon: "doc.text.magnifyingglass") {
                                model.runDiagnostic(
                                    ["debug", "inspect", "--area", model.selectedArea.rawValue],
                                    label: "Inspect page"
                                )
                            }
                            DiagnosticButton("Authentication status", icon: "person.crop.circle.badge.questionmark") {
                                model.runDiagnostic(["debug", "auth-status"], label: "Authentication status")
                            }
                            if model.selectedArea != .playlists {
                                DiagnosticButton("Inspect first menu", icon: "list.bullet.rectangle") {
                                    model.runDiagnostic(
                                        ["debug", "inspect-menu", "--area", model.selectedArea.rawValue],
                                        label: "Inspect menu"
                                    )
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.top, 6)
                }

                GroupBox("Browser profile") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Selected browser", value: model.browser.displayName)
                        LabeledContent("Backend", value: model.backend.validationMessage)
                        Text("The app uses a dedicated browser profile. It never imports cookies from your everyday Chrome profile.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button {
                                model.nativeChromeLogin()
                            } label: {
                                Label("Open Native Chrome Login", systemImage: "globe")
                            }
                            Button {
                                model.verifyAccount()
                            } label: {
                                Label("Verify Active Profile", systemImage: "person.crop.circle.badge.checkmark")
                            }
                            Spacer()
                        }
                    }
                    .padding(.top, 6)
                }

                GroupBox("Runtime") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Bundled Python runtime", value: model.backend.pythonExecutable.path)
                        LabeledContent("Worker source", value: model.backend.sourceDirectory.path)
                        LabeledContent("Action delay", value: String(format: "%.2f seconds", model.delay))
                    }
                    .font(.callout)
                    .textSelection(.enabled)
                    .padding(.top, 6)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Diagnostics")
        .disabled(model.isRunning)
    }
}

private struct DiagnosticButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.bordered)
    }
}
