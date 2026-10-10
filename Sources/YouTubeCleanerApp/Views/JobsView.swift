import SwiftUI
import YouTubeCleanerCore

struct JobsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedJobID: String?
    @State private var pendingResume: ResumeRequest?
    @State private var confirmClearHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resumable jobs")
                        .font(.largeTitle.bold())
                    Text("Every cleanup checkpoints verified progress locally.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    confirmClearHistory = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(model.jobs.isEmpty || model.isRunning)

                Button {
                    model.refreshJobs()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            if model.jobs.isEmpty {
                ContentUnavailableView(
                    "No saved jobs",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("A checkpoint appears here after a cleanup begins.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.jobs, selection: $selectedJobID) { job in
                    JobRow(job: job)
                        .tag(job.jobID)
                }
                .listStyle(.inset)
            }

            HStack {
                if let selectedJob {
                    Text(selectedJob.jobID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Select a job to inspect or resume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Show Details") {
                    guard let selectedJobID else { return }
                    model.showJob(selectedJobID)
                }
                Button("Resume One Item") {
                    guard let selectedJobID else { return }
                    pendingResume = ResumeRequest(jobID: selectedJobID, canary: true)
                }
                Button("Resume Job") {
                    guard let selectedJobID else { return }
                    pendingResume = ResumeRequest(jobID: selectedJobID, canary: false)
                }
                .buttonStyle(.borderedProminent)
            }
            .disabled(selectedJobID == nil || model.isRunning)
        }
        .padding(24)
        .navigationTitle("Jobs")
        .onAppear { model.refreshJobs() }
        .alert(item: $pendingResume) { request in
            Alert(
                title: Text(request.canary ? "Resume one item?" : "Resume cleanup?"),
                message: Text("The active YouTube profile must match the profile stored with this job."),
                primaryButton: .cancel(),
                secondaryButton: .default(Text("Resume")) {
                    model.resumeJob(request.jobID, canary: request.canary)
                }
            )
        }
        .confirmationDialog(
            "Clear all job history?",
            isPresented: $confirmClearHistory
        ) {
            Button("Move All Jobs to Trash", role: .destructive) {
                selectedJobID = nil
                model.clearJobHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This includes unfinished checkpoints. The files can be recovered from the macOS Trash until it is emptied.")
        }
    }

    private var selectedJob: JobRecord? {
        model.jobs.first { $0.jobID == selectedJobID }
    }
}

private struct ResumeRequest: Identifiable {
    let jobID: String
    let canary: Bool
    var id: String { "\(jobID)-\(canary)" }
}

private struct JobRow: View {
    let job: JobRecord

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: job.remaining.isEmpty ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(job.remaining.isEmpty ? .green : .orange)

            VStack(alignment: .leading, spacing: 3) {
                Text(job.operation.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let account = job.accountHandle ?? job.accountName {
                        Text(account)
                    }
                    Text(job.updatedAt.replacingOccurrences(of: "T", with: " ").prefix(19))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            JobCount(value: job.completed.count, label: "done", color: .green)
            JobCount(value: job.failed.count, label: "failed", color: .red)
            JobCount(value: job.remaining.count, label: "left", color: .orange)
        }
        .padding(.vertical, 5)
    }
}

private struct JobCount: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 45)
    }
}
