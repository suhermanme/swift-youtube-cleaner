import Foundation

struct BackendConfiguration: Equatable {
    var pythonExecutable: URL {
        let root = Bundle.main.resourceURL!.appendingPathComponent("PythonRuntime")
        let installations = (try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        )) ?? []
        return installations.first(where: { $0.lastPathComponent.hasPrefix("cpython-3.14.") })?
            .appendingPathComponent("bin/python3.14")
            ?? URL(fileURLWithPath: "/usr/bin/false")
    }

    var pythonPackagesDirectory: URL {
        Bundle.main.resourceURL!.appendingPathComponent("python-packages")
    }

    var sourceDirectory: URL {
        Bundle.main.resourceURL!.appendingPathComponent("youtube_cleaner")
    }

    var browserDirectory: URL {
        Bundle.main.resourceURL!.appendingPathComponent("playwright-browsers")
    }

    var isValid: Bool {
        FileManager.default.isExecutableFile(atPath: pythonExecutable.path)
            && FileManager.default.fileExists(atPath: sourceDirectory.appendingPathComponent("__main__.py").path)
            && FileManager.default.fileExists(atPath: pythonPackagesDirectory.path)
            && FileManager.default.fileExists(atPath: browserDirectory.path)
    }

    var validationMessage: String {
        isValid
            ? "Bundled Python worker and browser are ready."
            : "The bundled Python runtime, worker, packages, or browser are missing."
    }

    static var jobsDirectory: URL {
        let environment = ProcessInfo.processInfo.environment
        let stateRoot: URL
        if let xdgState = environment["XDG_STATE_HOME"], !xdgState.isEmpty {
            stateRoot = URL(fileURLWithPath: NSString(string: xdgState).expandingTildeInPath)
        } else {
            stateRoot = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".local/state")
        }
        return stateRoot.appendingPathComponent("youtube-cleaner/jobs")
    }

    static var chromeProfileDirectory: URL {
        let environment = ProcessInfo.processInfo.environment
        let dataRoot: URL
        if let xdgData = environment["XDG_DATA_HOME"], !xdgData.isEmpty {
            dataRoot = URL(fileURLWithPath: NSString(string: xdgData).expandingTildeInPath)
        } else {
            dataRoot = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".local/share")
        }
        return dataRoot.appendingPathComponent("youtube-cleaner/browser-profile")
    }
}
