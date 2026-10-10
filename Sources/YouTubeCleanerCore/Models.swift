import Foundation

public enum BrowserChoice: String, CaseIterable, Codable, Identifiable, Sendable {
    case chrome
    case chromium

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chrome: "Google Chrome"
        case .chromium: "Playwright Chromium"
        }
    }
}

public enum LibraryArea: String, CaseIterable, Codable, Identifiable, Sendable {
    case likes
    case watchLater = "watch-later"
    case playlists

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .likes: "Liked videos"
        case .watchLater: "Watch Later"
        case .playlists: "Playlists"
        }
    }
}

public struct CleanupRequest: Equatable, Sendable {
    public var area: LibraryArea
    public var execute: Bool
    public var allItems: Bool
    public var limit: Int?
    public var titleContains: String?
    public var channelName: String?
    public var discoverMore: Bool

    public init(
        area: LibraryArea,
        execute: Bool,
        allItems: Bool = true,
        limit: Int? = nil,
        titleContains: String? = nil,
        channelName: String? = nil,
        discoverMore: Bool = false
    ) {
        self.area = area
        self.execute = execute
        self.allItems = allItems
        self.limit = limit
        self.titleContains = titleContains
        self.channelName = channelName
        self.discoverMore = discoverMore
    }
}

public struct ProgressEvent: Codable, Equatable, Sendable {
    public let jobID: String
    public let operation: String
    public let phase: String
    public let message: String
    public let attemptedThisRun: Int
    public let targetsThisRun: Int
    public let completed: Int
    public let failed: Int
    public let skipped: Int
    public let remaining: Int
    public let currentTargetID: String?
    public let currentTitle: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case operation
        case phase
        case message
        case attemptedThisRun = "attempted_this_run"
        case targetsThisRun = "targets_this_run"
        case completed
        case failed
        case skipped
        case remaining
        case currentTargetID = "current_target_id"
        case currentTitle = "current_title"
    }

    public var fractionCompleted: Double {
        guard targetsThisRun > 0 else { return 0 }
        return min(1, Double(attemptedThisRun) / Double(targetsThisRun))
    }

    public var detail: String {
        var value = "\(phase): \(message)"
        if let currentTitle, !currentTitle.isEmpty {
            value += " · \(currentTitle)"
        }
        return value
    }
}

public struct JobRecord: Decodable, Identifiable, Sendable {
    public let jobID: String
    public let operation: String
    public let accountName: String?
    public let accountHandle: String?
    public let completed: [String]
    public let failed: [String: String]
    public let skipped: [String: String]
    public let remaining: [JobTarget]
    public let updatedAt: String

    public var id: String { jobID }

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case operation
        case accountName = "account_name"
        case accountHandle = "account_handle"
        case completed
        case failed
        case skipped
        case remaining
        case updatedAt = "updated_at"
    }
}

public struct JobTarget: Decodable, Sendable {
    public let targetID: String
    public let title: String

    enum CodingKeys: String, CodingKey {
        case targetID = "target_id"
        case title
    }
}
