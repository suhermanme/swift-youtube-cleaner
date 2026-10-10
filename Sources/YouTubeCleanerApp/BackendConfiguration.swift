import Foundation

struct BackendConfiguration: Equatable {
    let projectDirectory: URL

    var pythonExecutable: URL {
        projectDirectory.appendingPathComponent(".venv/bin/python")
    }

    var sourceDirectory: URL {
        projectDirectory.appendingPathComponent("src/youtube_cleaner")
    }

    var isValid: Bool {
        FileManager.default.isExecutableFile(atPath: pythonExecutable.path)
            && FileManager.default.fileExists(atPath: sourceDirectory.path)
    }

    var validationMessage: String {
        if !FileManager.default.fileExists(atPath: sourceDirectory.path) {
            return "The selected folder does not contain src/youtube_cleaner."
        }
        if !FileManager.default.isExecutableFile(atPath: pythonExecutable.path) {
            return "The backend virtual environment is missing. Run uv sync in the Python project."
        }
        return "Python automation engine is ready."
    }

    static func defaultProjectPath() -> String {
        if let override = ProcessInfo.processInfo.environment["YOUTUBE_CLEANER_PROJECT"],
           !override.isEmpty {
            return NSString(string: override).expandingTildeInPath
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/02_MULTI_SYNC/04_OPREK/WORKSPACE/YT_Clenaer")
            .path
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
