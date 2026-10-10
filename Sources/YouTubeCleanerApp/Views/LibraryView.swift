import SwiftUI
import YouTubeCleanerCore

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmExecution = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                backendNotice
                accountSection
                scanSection
                cleanupSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Library")
        .alert("Execute cleanup?", isPresented: $confirmExecution) {
            Button("Cancel", role: .cancel) {}
            Button("Execute", role: .destructive) {
                model.runCleanup(execute: true)
            }
        } message: {
            Text("YouTube Cleaner will verify the active profile again, checkpoint every confirmed change, and stop if the page becomes ambiguous.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Your YouTube library, under control")
                .font(.largeTitle.bold())
            Text("Inspect first, preview every cleanup, then execute against the verified profile.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var backendNotice: some View {
        if !model.backend.isValid {
            Label(model.backend.validationMessage, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var accountSection: some View {
        GroupBox("Account") {
            HStack(spacing: 10) {
                ActionButton("Verify account", icon: "person.crop.circle.badge.checkmark") {
                    model.verifyAccount()
                }
                ActionButton("Native Chrome login", icon: "globe") {
                    model.nativeChromeLogin()
                }
                ActionButton("Playwright login", icon: "person.badge.key") {
                    model.login()
                }
                Spacer()
            }
            .padding(.top, 6)
        }
        .disabled(model.isRunning || !model.backend.isValid)
    }

    private var scanSection: some View {
        GroupBox("Read-only scan and export") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Library area", selection: $model.selectedArea) {
                    ForEach(LibraryArea.allCases) { area in
                        Text(area.displayName).tag(area)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Button {
                        model.scan()
                    } label: {
                        Label("Scan \(model.selectedArea.displayName)", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)

                    Menu {
                        Button("Export JSON") { model.export(model.selectedArea, format: "json") }
                        Button("Export CSV") { model.export(model.selectedArea, format: "csv") }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                }
            }
            .padding(.top, 6)
        }
        .disabled(model.isRunning || !model.backend.isValid)
    }

    private var cleanupSection: some View {
        GroupBox("Cleanup") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 22) {
                    Toggle("All items", isOn: $model.allItems)

                    Toggle("Limit", isOn: $model.limitEnabled)
                    Stepper(value: $model.limit, in: 1...1_000_000) {
                        Text(model.limitEnabled ? "\(model.limit) item\(model.limit == 1 ? "" : "s")" : "No limit")
                            .frame(minWidth: 90, alignment: .leading)
                    }
                    .disabled(!model.limitEnabled)
                    Spacer()
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        Text("Title contains")
                            .foregroundStyle(.secondary)
                        TextField("Optional title text", text: $model.titleFilter)
                    }
                    GridRow {
                        Text("Channel name")
                            .foregroundStyle(.secondary)
                        TextField("Optional channel or owner", text: $model.channelFilter)
                    }
                }

                Toggle("Keep discovering until repeated scans find nothing new", isOn: $model.discoverMore)
                    .help("Available only for All items with no limit or filters")

                if model.selectedArea == .playlists {
                    Label(
                        "Owned playlists may be permanently deleted; saved external playlists are removed from the Library.",
                        systemImage: "exclamationmark.shield"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Label("Start with a preview or a one-item canary.", systemImage: "shield.checkered")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Preview / Dry Run") {
                        model.runCleanup(execute: false)
                    }
                    .buttonStyle(.bordered)
                    Button("Execute Cleanup", role: .destructive) {
                        confirmExecution = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(.top, 6)
        }
        .disabled(model.isRunning || !model.backend.isValid)
    }
}

private struct ActionButton: View {
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
