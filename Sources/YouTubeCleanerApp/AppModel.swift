import AppKit
import Foundation
import YouTubeCleanerCore

@MainActor
final class AppModel: ObservableObject {
    private enum DefaultsKey {
        static let backendPath = "backendProjectPath"
        static let browser = "selectedBrowser"
        static let delay = "actionDelay"
        static let debug = "debugMode"
    }

    @Published var backendProjectPath: String {
        didSet { defaults.set(backendProjectPath, forKey: DefaultsKey.backendPath) }
    }
    @Published var browser: BrowserChoice {
        didSet { defaults.set(browser.rawValue, forKey: DefaultsKey.browser) }
    }
    @Published var delay: Double {
        didSet { defaults.set(delay, forKey: DefaultsKey.delay) }
    }
    @Published var debugMode: Bool {
        didSet { defaults.set(debugMode, forKey: DefaultsKey.debug) }
    }

    @Published var selectedArea: LibraryArea = .likes
    @Published var allItems = true
    @Published var limitEnabled = false
    @Published var limit = 1
    @Published var titleFilter = ""
    @Published var channelFilter = ""
    @Published var discoverMore = false

    @Published private(set) var isRunning = false
    @Published private(set) var status = "Ready"
    @Published private(set) var activityLog = ""
    @Published private(set) var progress: ProgressEvent?
    @Published private(set) var jobs: [JobRecord] = []
    @Published private(set) var nativeLoginActive = false
    @Published private(set) var nativeLoginLaunching = false
    @Published private(set) var nativeLoginFinishing = false
    @Published private(set) var nativeLoginError: String?
    @Published var userError: String?

    private let defaults: UserDefaults
    private let runner = CleanerProcess()
    private var nativeChromeApplication: NSRunningApplication?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        backendProjectPath = defaults.string(forKey: DefaultsKey.backendPath)
            ?? BackendConfiguration.defaultProjectPath()
        browser = BrowserChoice(
            rawValue: defaults.string(forKey: DefaultsKey.browser) ?? "chrome"
        ) ?? .chrome
        let storedDelay = defaults.double(forKey: DefaultsKey.delay)
        delay = storedDelay > 0 ? storedDelay : 1.5
        debugMode = defaults.bool(forKey: DefaultsKey.debug)
        refreshJobs()
    }

    var backend: BackendConfiguration {
        BackendConfiguration(projectDirectory: URL(fileURLWithPath: backendProjectPath))
    }

    func verifyAccount() {
        run(["account"], label: "Verify account")
    }

    func login() {
        run(["browser", "login"], label: "Browser login")
    }

    func nativeChromeLogin() {
        guard !isRunning, !nativeLoginActive else {
            userError = "Finish or stop the current operation first."
            return
        }

        browser = .chrome
        nativeLoginError = nil
        nativeLoginLaunching = true
        nativeLoginActive = true
        status = "Opening dedicated Chrome…"

        do {
            try FileManager.default.createDirectory(
                at: BackendConfiguration.chromeProfileDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            nativeLoginLaunching = false
            nativeLoginActive = false
            status = "Unable to open Chrome"
            userError = "Could not prepare the dedicated Chrome profile. \(error.localizedDescription)"
            return
        }

        guard let chromeURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.google.Chrome"
        ) else {
            nativeLoginLaunching = false
            nativeLoginActive = false
            status = "Chrome not found"
            userError = "Google Chrome is not installed in Applications."
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = [
            "--user-data-dir=\(BackendConfiguration.chromeProfileDirectory.path)",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-background-mode",
            "https://www.youtube.com/",
        ]
        configuration.activates = true
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(
            at: chromeURL,
            configuration: configuration
        ) { [weak self] application, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                guard self.nativeLoginActive else {
                    if let application, !application.isTerminated {
                        application.terminate()
                    }
                    return
                }

                self.nativeLoginLaunching = false
                guard let application, error == nil else {
                    self.nativeLoginActive = false
                    self.status = "Unable to open Chrome"
                    self.userError = error?.localizedDescription
                        ?? "macOS did not return the dedicated Chrome application."
                    return
                }

                self.nativeChromeApplication = application
                self.status = "Waiting for Chrome sign-in"
                self.appendLog("\nDedicated Chrome opened for sign-in.\n")
            }
        }
    }

    func finishNativeChromeLogin() {
        guard nativeLoginActive, !nativeLoginLaunching, !nativeLoginFinishing else { return }
        nativeLoginFinishing = true
        nativeLoginError = nil
        status = "Closing dedicated Chrome…"

        Task { @MainActor [weak self] in
            guard let self else { return }
            if let application = self.nativeChromeApplication,
               !application.isTerminated {
                self.appendLog("\nClosing the dedicated Chrome application…\n")
                application.terminate()

                for _ in 0..<50 {
                    guard self.nativeLoginActive else { return }
                    if application.isTerminated { break }
                    try? await Task.sleep(for: .milliseconds(200))
                }

                if !application.isTerminated {
                    self.appendLog("Chrome did not exit after 10 seconds; forcing only the dedicated application instance to close.\n")
                    application.forceTerminate()
                    for _ in 0..<25 {
                        guard self.nativeLoginActive else { return }
                        if application.isTerminated { break }
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                }
            }

            if let application = self.nativeChromeApplication,
               !application.isTerminated {
                self.nativeLoginFinishing = false
                self.status = "Waiting for Chrome to close"
                self.nativeLoginError = "The dedicated Chrome application is still running. Quit that window manually, then choose Try Again."
                return
            }

            self.nativeChromeApplication = nil
            self.nativeLoginActive = false
            self.nativeLoginFinishing = false
            self.nativeLoginError = nil
            self.status = "Verifying login…"
            try? await Task.sleep(for: .milliseconds(500))
            self.verifyAccount()
        }
    }

    func cancelNativeChromeLogin() {
        if let application = nativeChromeApplication, !application.isTerminated {
            if !application.terminate() {
                application.forceTerminate()
            }
        }
        nativeChromeApplication = nil
        nativeLoginActive = false
        nativeLoginLaunching = false
        nativeLoginFinishing = false
        nativeLoginError = nil
        status = isRunning ? status : "Ready"
    }

    func scan(_ area: LibraryArea? = nil) {
        let area = area ?? selectedArea
        run(["scan", area.rawValue], label: "Scan \(area.displayName)")
    }

    func export(_ area: LibraryArea, format: String) {
        run(["export", area.rawValue, "--format", format], label: "Export \(area.displayName)")
    }

    func runCleanup(execute: Bool) {
        let request = CleanupRequest(
            area: selectedArea,
            execute: execute,
            allItems: allItems,
            limit: limitEnabled ? limit : nil,
            titleContains: titleFilter,
            channelName: channelFilter,
            discoverMore: discoverMore
        )
        do {
            let arguments = try CommandBuilder.cleanup(request)
            run(arguments, label: execute ? "Execute cleanup" : "Preview cleanup")
        } catch {
            userError = error.localizedDescription
        }
    }

    func showJob(_ jobID: String) {
        run(["jobs", "show", jobID], label: "Show job")
    }

    func resumeJob(_ jobID: String, canary: Bool) {
        do {
            let arguments = try CommandBuilder.resume(jobID: jobID, limit: canary ? 1 : nil)
            run(arguments, label: canary ? "Resume one item" : "Resume job")
        } catch {
            userError = error.localizedDescription
        }
    }

    func runDiagnostic(_ arguments: [String], label: String) {
        run(arguments, label: label)
    }

    func sendContinue() {
        runner.sendContinue()
        appendLog("\n[Continue sent]\n")
    }

    func stopSafely() {
        guard isRunning else { return }
        status = "Stopping safely…"
        appendLog("\nSending a safe interrupt; waiting for the current checkpoint…\n")
        runner.stopSafely()
    }

    func clearLog() {
        activityLog = ""
    }

    func refreshJobs() {
        let directory = BackendConfiguration.jobsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            jobs = []
            return
        }

        let decoder = JSONDecoder()
        jobs = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(JobRecord.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func clearJobHistory() {
        guard !isRunning else {
            userError = "Finish or stop the current operation before clearing job history."
            return
        }

        let directory = BackendConfiguration.jobsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            jobs = []
            return
        }

        let jobFiles = files.filter { $0.pathExtension.lowercased() == "json" }
        var clearedCount = 0
        var failures: [Error] = []

        for file in jobFiles {
            do {
                try FileManager.default.trashItem(at: file, resultingItemURL: nil)
                clearedCount += 1
            } catch {
                failures.append(error)
            }
        }

        refreshJobs()
        if clearedCount > 0 {
            appendLog("\nMoved \(clearedCount) saved job\(clearedCount == 1 ? "" : "s") to the Trash.\n")
        }
        if let failure = failures.first {
            userError = "Could not clear \(failures.count) job\(failures.count == 1 ? "" : "s"). \(failure.localizedDescription)"
        }
    }

    @discardableResult
    private func run(_ command: [String], label: String) -> Bool {
        guard !isRunning else {
            userError = "Finish or stop the current operation first."
            return false
        }

        let displayedCommand = (["youtube-cleaner", "--browser", browser.rawValue] + command)
            .map(Self.shellDisplay)
            .joined(separator: " ")
        appendLog("\n› \(displayedCommand)\n")
        progress = nil
        status = label

        do {
            try runner.start(
                configuration: backend,
                browser: browser,
                delay: delay,
                debug: debugMode,
                command: command,
                onOutput: { [weak self] text in self?.appendWorkerOutput(text) },
                onProgress: { [weak self] event in
                    self?.progress = event
                    self?.appendLog("\(event.detail)\n")
                },
                onFinish: { [weak self] exitCode in
                    guard let self else { return }
                    self.isRunning = false
                    self.nativeLoginActive = false
                    self.nativeLoginLaunching = false
                    self.nativeLoginFinishing = false
                    self.nativeLoginError = nil
                    self.status = exitCode == 0 ? "Ready" : "Failed (\(exitCode))"
                    self.appendLog("\nOperation finished with exit code \(exitCode).\n")
                    self.refreshJobs()
                }
            )
            isRunning = true
            return true
        } catch {
            status = "Unable to start"
            userError = error.localizedDescription
            return false
        }
    }

    private func appendWorkerOutput(_ text: String) {
        let hiddenPrefixes = [
            "Opening installed Chrome without Playwright control.",
            "Dedicated profile:",
            "1. Sign in to YouTube manually",
            "2. Confirm the intended YouTube channel",
            "3. Completely quit that dedicated Chrome window.",
            "After Chrome has completely quit, press Enter",
        ]
        let visible = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { line in
                !hiddenPrefixes.contains { line.trimmingCharacters(in: .whitespaces).hasPrefix($0) }
            }
            .joined(separator: "\n")
        if !visible.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            appendLog(visible)
        }
    }

    private func appendLog(_ text: String) {
        activityLog += text
        if activityLog.count > 250_000 {
            activityLog.removeFirst(activityLog.count - 200_000)
        }
    }

    private static func shellDisplay(_ argument: String) -> String {
        if argument.allSatisfy({ $0.isLetter || $0.isNumber || "-._/".contains($0) }) {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

}
