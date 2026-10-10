import Darwin
import Foundation
import YouTubeCleanerCore

@MainActor
final class CleanerProcess {
    private var process: Process?
    private var outputPipe: Pipe?
    private var inputPipe: Pipe?
    private var parser = OutputParser()

    private var onOutput: ((String) -> Void)?
    private var onProgress: ((ProgressEvent) -> Void)?
    private var onFinish: ((Int32) -> Void)?

    var isRunning: Bool { process?.isRunning == true }

    deinit {
        if let process, process.isRunning {
            Darwin.kill(process.processIdentifier, SIGINT)
        }
    }

    func start(
        configuration: BackendConfiguration,
        browser: BrowserChoice,
        delay: Double,
        debug: Bool,
        command: [String],
        onOutput: @escaping (String) -> Void,
        onProgress: @escaping (ProgressEvent) -> Void,
        onFinish: @escaping (Int32) -> Void
    ) throws {
        guard process == nil else {
            throw RunnerError.alreadyRunning
        }
        guard configuration.isValid else {
            throw RunnerError.invalidBackend(configuration.validationMessage)
        }

        self.onOutput = onOutput
        self.onProgress = onProgress
        self.onFinish = onFinish
        parser = OutputParser()

        var arguments = [
            "-m", "youtube_cleaner",
            "--browser", browser.rawValue,
            "--delay", String(format: "%.2f", delay),
        ]
        if debug { arguments.append("--debug") }
        arguments.append(contentsOf: command)

        let process = Process()
        let outputPipe = Pipe()
        let inputPipe = Pipe()
        process.executableURL = configuration.pythonExecutable
        process.arguments = arguments
        process.currentDirectoryURL = configuration.projectDirectory
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe

        var environment = ProcessInfo.processInfo.environment
        environment["NO_COLOR"] = "1"
        environment["TERM"] = "dumb"
        environment["PYTHONUNBUFFERED"] = "1"
        environment["YOUTUBE_CLEANER_GUI_PROGRESS"] = "1"
        environment["COLUMNS"] = "200"
        process.environment = environment

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.consume(text)
            }
        }

        process.terminationHandler = { [weak self] finishedProcess in
            Task { @MainActor [weak self] in
                self?.didFinish(exitCode: finishedProcess.terminationStatus)
            }
        }

        self.process = process
        self.outputPipe = outputPipe
        self.inputPipe = inputPipe

        do {
            try process.run()
        } catch {
            clearProcess()
            throw error
        }
    }

    func sendContinue() {
        guard let inputPipe else { return }
        inputPipe.fileHandleForWriting.write(Data("\n".utf8))
    }

    func stopSafely() {
        guard let process, process.isRunning else { return }
        Darwin.kill(process.processIdentifier, SIGINT)
    }

    private func consume(_ text: String) {
        for message in parser.consume(text) {
            switch message {
            case .output(let text):
                onOutput?(text)
            case .progress(let event):
                onProgress?(event)
            }
        }
    }

    private func didFinish(exitCode: Int32) {
        for message in parser.finish() {
            if case .output(let text) = message { onOutput?(text) }
            if case .progress(let event) = message { onProgress?(event) }
        }
        let completion = onFinish
        clearProcess()
        completion?(exitCode)
    }

    private func clearProcess() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        process = nil
        outputPipe = nil
        inputPipe = nil
        onOutput = nil
        onProgress = nil
        onFinish = nil
    }
}

enum RunnerError: LocalizedError {
    case alreadyRunning
    case invalidBackend(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            "Another operation is already running."
        case .invalidBackend(let message):
            message
        }
    }
}
