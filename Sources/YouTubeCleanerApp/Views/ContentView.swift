import AppKit
import SwiftUI
import YouTubeCleanerCore

private enum AppSection: String, CaseIterable, Identifiable {
    case library = "Library"
    case jobs = "Jobs"
    case diagnostics = "Diagnostics"
    case help = "Help"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library: "rectangle.stack"
        case .jobs: "clock.arrow.circlepath"
        case .diagnostics: "stethoscope"
        case .help: "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: AppSection? = .library

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("YouTube Cleaner")
            .navigationSplitViewColumnWidth(min: 180, ideal: 205)
        } detail: {
            VSplitView {
                Group {
                    switch selection ?? .library {
                    case .library:
                        LibraryView()
                    case .jobs:
                        JobsView()
                    case .diagnostics:
                        DiagnosticsView()
                    case .help:
                        HelpView()
                    }
                }
                .frame(minHeight: 350)

                ActivityView()
                    .frame(minHeight: 190, idealHeight: 245)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Browser", selection: $model.browser) {
                    ForEach(BrowserChoice.allCases) { browser in
                        Text(browser.displayName).tag(browser)
                    }
                }
                .frame(width: 175)
                .disabled(model.isRunning || model.nativeLoginActive)

                StatusBadge(
                    text: model.status,
                    running: model.isRunning || model.nativeLoginActive
                )
            }
        }
        .alert(
            "YouTube Cleaner",
            isPresented: Binding(
                get: { model.userError != nil },
                set: { if !$0 { model.userError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.userError = nil }
        } message: {
            Text(model.userError ?? "")
        }
        .sheet(isPresented: Binding(
            get: { model.nativeLoginActive },
            set: { isPresented in
                if !isPresented, model.nativeLoginActive {
                    model.cancelNativeChromeLogin()
                }
            }
        )) {
            NativeChromeLoginView()
                .environmentObject(model)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            if model.nativeLoginActive {
                model.cancelNativeChromeLogin()
            }
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let running: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(running ? Color.orange : Color.green)
                .frame(width: 7, height: 7)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}
