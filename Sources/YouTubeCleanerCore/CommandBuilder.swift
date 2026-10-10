import Foundation

public enum CommandValidationError: LocalizedError, Equatable {
    case invalidLimit
    case nothingSelected
    case discoverMoreRequiresUnrestrictedSelection

    public var errorDescription: String? {
        switch self {
        case .invalidLimit:
            "Limit must be at least 1."
        case .nothingSelected:
            "Select all items, set a limit, or enter a filter."
        case .discoverMoreRequiresUnrestrictedSelection:
            "Keep discovering requires All items with no limit or filters."
        }
    }
}

public enum CommandBuilder {
    public static func cleanup(_ request: CleanupRequest) throws -> [String] {
        if let limit = request.limit, limit < 1 {
            throw CommandValidationError.invalidLimit
        }

        let title = normalized(request.titleContains)
        let channel = normalized(request.channelName)
        guard request.allItems || request.limit != nil || title != nil || channel != nil else {
            throw CommandValidationError.nothingSelected
        }

        let unrestricted = request.allItems
            && request.limit == nil
            && title == nil
            && channel == nil
        if request.discoverMore && !unrestricted {
            throw CommandValidationError.discoverMoreRequiresUnrestrictedSelection
        }

        var arguments = [request.area.rawValue, "clean"]
        if request.allItems { arguments.append("--all") }
        if let limit = request.limit {
            arguments += ["--limit", String(limit)]
        }
        if let title {
            arguments += ["--title-contains", title]
        }
        if let channel {
            arguments += ["--channel-name", channel]
        }
        arguments.append(request.execute ? "--execute" : "--dry-run")
        if request.discoverMore { arguments.append("--discover-more") }
        return arguments
    }

    public static func resume(jobID: String, limit: Int? = nil, discoverMore: Bool = false) throws -> [String] {
        let jobID = jobID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !jobID.isEmpty else { throw CommandValidationError.nothingSelected }
        if let limit, limit < 1 { throw CommandValidationError.invalidLimit }
        if limit != nil && discoverMore {
            throw CommandValidationError.discoverMoreRequiresUnrestrictedSelection
        }

        var arguments = ["jobs", "resume", jobID]
        if let limit { arguments += ["--limit", String(limit)] }
        if discoverMore { arguments.append("--discover-more") }
        return arguments
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
