import SwiftUI

struct HelpView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                aboutSection
                setupSection
                workflowSection
                controlsSection
                navigationSection
                safetySection
                troubleshootingSection
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Help")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Help & Guide")
                .font(.largeTitle.bold())
            Text("What YouTube Cleaner does, how to use it, and how it protects your library.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        HelpSection(title: "What this app does", icon: "sparkles") {
            Text("YouTube Cleaner helps you inspect, export, and clean up Likes, Watch Later, and playlists from a native macOS interface.")

            Text("The app starts a local automation worker that operates the visible YouTube website in a dedicated browser profile. Scans, exports, and previews are read-only. Your YouTube library changes only after you choose Execute Cleanup and confirm the warning.")
                .foregroundStyle(.secondary)

            Label("YouTube's website can change. The worker stops when it cannot safely identify or verify an action.", systemImage: "exclamationmark.shield")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var setupSection: some View {
        HelpSection(title: "First-time setup", icon: "gearshape.2") {
            GuideStep(number: 1, title: "Check the bundled runtime") {
                Text("Open Settings and confirm the bundled worker and Python runtime are ready. No separate worker project is needed.")
            }
            GuideStep(number: 2, title: "Sign in with the dedicated profile") {
                Text("Select Google Chrome in the toolbar, choose Native Chrome login, sign in to YouTube, then return and choose Finish Login.")
            }
            GuideStep(number: 3, title: "Verify the account") {
                Text("In Library, choose Verify account and confirm the channel name and handle in Activity before doing any cleanup.")
            }

            Divider()

            LabeledContent("Backend", value: model.backend.validationMessage)
            LabeledContent("Selected browser", value: model.browser.displayName)
        }
    }

    private var workflowSection: some View {
        HelpSection(title: "Recommended cleanup workflow", icon: "checklist") {
            GuideStep(number: 1, title: "Scan the library area") {
                Text("Choose Likes, Watch Later, or Playlists, then run Scan. Read the results in Activity.")
            }
            GuideStep(number: 2, title: "Choose the scope") {
                Text("Clean all items or narrow the targets with a limit, title text, or channel name.")
            }
            GuideStep(number: 3, title: "Preview first") {
                Text("Choose Preview / Dry Run and inspect the planned targets. This does not modify YouTube.")
            }
            GuideStep(number: 4, title: "Run a one-item canary") {
                Text("Enable Limit and set it to 1. Execute the cleanup, then verify the result directly on YouTube.")
            }
            GuideStep(number: 5, title: "Execute the intended selection") {
                Text("Remove the canary limit only when the result is correct, then execute and follow progress in Activity.")
            }
        }
    }

    private var controlsSection: some View {
        HelpSection(title: "Understanding cleanup controls", icon: "slider.horizontal.3") {
            HelpTerm(term: "All items", explanation: "Targets the complete selected library area rather than a smaller default batch.")
            HelpTerm(term: "Limit", explanation: "Caps how many matching items the operation will process. Use 1 for a safe canary run.")
            HelpTerm(term: "Title contains", explanation: "Includes only items whose title matches the entered text.")
            HelpTerm(term: "Channel name", explanation: "Includes only items associated with the specified channel or owner.")
            HelpTerm(term: "Keep discovering", explanation: "Repeats discovery until scans stop finding new items. It is available only with All items, no limit, and no filters.")
            HelpTerm(term: "Stop Safely", explanation: "Interrupts the worker and allows it to save the current checkpoint before stopping.")
        }
    }

    private var navigationSection: some View {
        HelpSection(title: "Where to find things", icon: "sidebar.left") {
            HelpTerm(term: "Library", explanation: "Sign in, verify the account, scan or export an area, preview targets, and execute cleanup.")
            HelpTerm(term: "Jobs", explanation: "Inspect cleanup checkpoints, resume an interrupted job, or clear saved history. Cleared jobs are moved to the macOS Trash.")
            HelpTerm(term: "Diagnostics", explanation: "Check authentication, inspect page selectors, and review the selected browser and runtime paths.")
            HelpTerm(term: "Activity", explanation: "Shows commands, results, progress, warnings, and errors. It remains visible below every section.")
            HelpTerm(term: "Settings", explanation: "Choose the backend project, default browser, action delay, and optional debug diagnostics.")
        }
    }

    private var safetySection: some View {
        HelpSection(title: "Safety and recovery", icon: "lock.shield") {
            SafetyPoint(text: "The active YouTube profile is checked again before changes begin.")
            SafetyPoint(text: "Every confirmed change is checkpointed locally.")
            SafetyPoint(text: "Ambiguous controls or unverifiable results stop the operation instead of guessing.")
            SafetyPoint(text: "Owned playlists may be permanently deleted; saved external playlists are removed from your Library.")
            SafetyPoint(text: "The automation profile is separate from your everyday Chrome profile.")
        }
    }

    private var troubleshootingSection: some View {
        HelpSection(title: "If something goes wrong", icon: "wrench.and.screwdriver") {
            HelpTerm(term: "Bundled runtime missing", explanation: "Rebuild the application with ./scripts/build-app.sh to restore its worker, Python packages, and Chromium.")
            HelpTerm(term: "Not signed in", explanation: "Repeat Native Chrome login, close it with Finish Login, and run Verify account again.")
            HelpTerm(term: "Operation failed", explanation: "Read the final messages in Activity. Enable debug diagnostics in Settings before repeating a safe, read-only operation.")
            HelpTerm(term: "Interrupted cleanup", explanation: "Open Jobs, select its checkpoint, show the details, and use Resume One Item before resuming the full job.")
        }
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 13) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            Label(title, systemImage: icon)
                .font(.headline)
        }
    }
}

private struct GuideStep<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.callout.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                content
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HelpTerm: View {
    let term: String
    let explanation: String

    var body: some View {
        LabeledContent {
            Text(explanation)
                .foregroundStyle(.secondary)
        } label: {
            Text(term)
                .fontWeight(.medium)
        }
    }
}

private struct SafetyPoint: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }
}
