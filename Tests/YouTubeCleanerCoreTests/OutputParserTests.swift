import Testing
@testable import YouTubeCleanerCore

@Test func progressRecordsCanArriveInChunks() {
    var parser = OutputParser()
    let json = #"{"job_id":"clean-1","operation":"remove-liked","phase":"execute","message":"Removed","attempted_this_run":2,"targets_this_run":5,"completed":2,"failed":0,"skipped":0,"remaining":3,"current_target_id":"abc","current_title":"A video"}"#

    #expect(parser.consume("ordinary output\n__YOUTUBE_CLEANER_PROG") == [
        .output("ordinary output\n"),
    ])
    let messages = parser.consume("RESS__:\(json)\n")
    #expect(messages.count == 1)

    guard case .progress(let event) = messages.first else {
        Issue.record("Expected a progress event")
        return
    }
    #expect(event.jobID == "clean-1")
    #expect(event.attemptedThisRun == 2)
    #expect(event.targetsThisRun == 5)
    #expect(event.currentTitle == "A video")
}

@Test func invalidProgressRecordRemainsVisible() {
    var parser = OutputParser()
    #expect(parser.consume("__YOUTUBE_CLEANER_PROGRESS__:not-json\n") == [
        .output("__YOUTUBE_CLEANER_PROGRESS__:not-json\n"),
    ])
}

@Test func terminalColorCodesAreRemoved() {
    #expect(OutputParser.cleanTerminalText("\u{001B}[31mFailure\u{001B}[0m") == "Failure")
}
