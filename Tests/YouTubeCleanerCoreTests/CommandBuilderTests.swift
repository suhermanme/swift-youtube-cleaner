import Testing
@testable import YouTubeCleanerCore

@Test func dryRunCommandPreservesFilters() throws {
    let request = CleanupRequest(
        area: .likes,
        execute: false,
        allItems: false,
        limit: 10,
        titleContains: "  kids  ",
        channelName: nil
    )

    #expect(try CommandBuilder.cleanup(request) == [
        "likes", "clean", "--limit", "10", "--title-contains", "kids", "--dry-run",
    ])
}

@Test func executionRequiresASelection() {
    let request = CleanupRequest(area: .watchLater, execute: true, allItems: false)
    #expect(throws: CommandValidationError.nothingSelected) {
        try CommandBuilder.cleanup(request)
    }
}

@Test func continuousDiscoveryRequiresUnrestrictedAllItems() {
    let request = CleanupRequest(
        area: .playlists,
        execute: true,
        allItems: true,
        limit: 1,
        discoverMore: true
    )
    #expect(throws: CommandValidationError.discoverMoreRequiresUnrestrictedSelection) {
        try CommandBuilder.cleanup(request)
    }
}

@Test func allItemsExecutionCommand() throws {
    let request = CleanupRequest(
        area: .watchLater,
        execute: true,
        discoverMore: true
    )
    #expect(try CommandBuilder.cleanup(request) == [
        "watch-later", "clean", "--all", "--execute", "--discover-more",
    ])
}
