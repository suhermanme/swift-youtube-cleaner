import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("Activity")
                    .font(.headline)

                if let progress = model.progress {
                    ProgressView(value: progress.fractionCompleted)
                        .frame(maxWidth: 180)
                    Text("\(progress.attemptedThisRun) / \(progress.targetsThisRun)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.isRunning {
                    if !model.nativeLoginActive {
                        Button("Continue") { model.sendContinue() }
                            .help("Continue an interactive diagnostic command")
                    }
                    Button("Stop Safely", role: .destructive) { model.stopSafely() }
                }
                Button("Clear") { model.clearLog() }
                    .disabled(model.activityLog.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.bar)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(model.activityLog.isEmpty ? "Operations and diagnostics will appear here." : model.activityLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(model.activityLog.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                    Color.clear.frame(height: 1).id("activity-bottom")
                }
                .onChange(of: model.activityLog) { _, _ in
                    proxy.scrollTo("activity-bottom", anchor: .bottom)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }
}
