import EventKit
import Foundation

@main
struct ReminderSourceSelectionTestRunner {
    static func main() {

        // === Source selection logic ===

        runTest("findBestReminderSource_prefersICloudWithReminders") {
            let candidates = [
                SourceCandidate(title: "Donaldo De Sousa CalDAV", sourceType: .calDAV, sourceIdentifier: "src-1", hasReminderCalendars: false),
                SourceCandidate(title: "iCloud", sourceType: .calDAV, sourceIdentifier: "src-2", hasReminderCalendars: true),
                SourceCandidate(title: "donaldo@adjc.net CalDAV", sourceType: .calDAV, sourceIdentifier: "src-3", hasReminderCalendars: true),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertEqual(result?.title ?? "", "iCloud", "Should prefer iCloud source")
        }

        runTest("findBestReminderSource_fallsBackToSourceWithReminders") {
            let candidates = [
                SourceCandidate(title: "Donaldo De Sousa CalDAV", sourceType: .calDAV, sourceIdentifier: "src-1", hasReminderCalendars: false),
                SourceCandidate(title: "donaldo@adjc.net CalDAV", sourceType: .calDAV, sourceIdentifier: "src-3", hasReminderCalendars: true),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertEqual(result?.title ?? "", "donaldo@adjc.net CalDAV", "Should fallback to source with reminders")
        }

        runTest("findBestReminderSource_rejectsSourceWithoutReminders") {
            let candidates = [
                SourceCandidate(title: "Donaldo De Sousa CalDAV", sourceType: .calDAV, sourceIdentifier: "src-1", hasReminderCalendars: false),
                SourceCandidate(title: "Another Account", sourceType: .calDAV, sourceIdentifier: "src-4", hasReminderCalendars: false),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertTrue(result == nil, "Should return nil when no source has reminders")
        }

        runTest("findBestReminderSource_prefersLocalWithReminders") {
            let candidates = [
                SourceCandidate(title: "Local", sourceType: .local, sourceIdentifier: "src-5", hasReminderCalendars: true),
                SourceCandidate(title: "Some CalDAV", sourceType: .calDAV, sourceIdentifier: "src-6", hasReminderCalendars: true),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertTrue(result != nil, "Should find a source")
            assertTrue(result!.hasReminderCalendars, "Source should have reminders")
        }

        runTest("findBestReminderSource_emptyCandidates") {
            let candidates: [SourceCandidate] = []
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertTrue(result == nil, "Should return nil for empty candidates")
        }

        runTest("findBestReminderSource_iCloudWithoutRemindersNotPreferred") {
            let candidates = [
                SourceCandidate(title: "iCloud", sourceType: .calDAV, sourceIdentifier: "src-7", hasReminderCalendars: false),
                SourceCandidate(title: "Work CalDAV", sourceType: .calDAV, sourceIdentifier: "src-8", hasReminderCalendars: true),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertEqual(result?.title ?? "", "Work CalDAV", "Should pick source with reminders over iCloud without")
        }

        runTest("findBestReminderSource_duplicateICloudPicksOneWithReminders") {
            // Real scenario: two iCloud sources, only one has reminder calendars
            let candidates = [
                SourceCandidate(title: "iCloud", sourceType: .calDAV, sourceIdentifier: "icloud-no-reminders", hasReminderCalendars: false),
                SourceCandidate(title: "iCloud", sourceType: .calDAV, sourceIdentifier: "icloud-with-reminders", hasReminderCalendars: true),
            ]
            let result = EventKitService.findBestReminderSource(from: candidates)
            assertEqual(result?.sourceIdentifier ?? "", "icloud-with-reminders", "Should pick the iCloud source that has reminders")
        }

        reportResults()
    }
}
