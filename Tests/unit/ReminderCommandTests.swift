import Foundation

@main
struct ReminderCommandTestRunner {
    static func main() {

        // === US-008: Lists command — text & JSON formatter already tested ===
        // Service-level tests are integration (need real EventKit)
        // Unit-testable: formatter coverage is in ReminderFormatterTests.swift

        // === US-009: List command — ListReminderArgs parsing ===

        runTest("parseListReminderArgs_defaults") {
            let args: [String] = []
            let parsed = ListReminderArgs.parse(args)
            assertTrue(parsed.listName == nil, "Default list should be nil")
            assertFalse(parsed.includeCompleted, "Default should not include completed")
            assertTrue(parsed.dueBefore == nil, "Default due-before should be nil")
            assertFalse(parsed.useJSON, "Default should not use JSON")
        }

        runTest("parseListReminderArgs_allOptions") {
            let args = ["--list", "Courses", "--completed", "--due-before", "2026-04-01", "--json"]
            let parsed = ListReminderArgs.parse(args)
            assertEqual(parsed.listName ?? "", "Courses")
            assertTrue(parsed.includeCompleted, "Should include completed")
            assertEqual(parsed.dueBefore ?? "", "2026-04-01")
            assertTrue(parsed.useJSON, "Should use JSON")
        }

        runTest("parseListReminderArgs_listOnly") {
            let args = ["--list", "Travail"]
            let parsed = ListReminderArgs.parse(args)
            assertEqual(parsed.listName ?? "", "Travail")
            assertFalse(parsed.includeCompleted)
            assertTrue(parsed.dueBefore == nil)
            assertFalse(parsed.useJSON)
        }

        runTest("parseListReminderArgs_completedFlag") {
            let args = ["--completed"]
            let parsed = ListReminderArgs.parse(args)
            assertTrue(parsed.includeCompleted, "Should enable completed filter")
        }

        runTest("parseListReminderArgs_dueBefore") {
            let args = ["--due-before", "2026-05-15"]
            let parsed = ListReminderArgs.parse(args)
            assertEqual(parsed.dueBefore ?? "", "2026-05-15")
        }

        runTest("parseListReminderArgs_json") {
            let args = ["--json"]
            let parsed = ListReminderArgs.parse(args)
            assertTrue(parsed.useJSON, "Should enable JSON output")
        }

        // === US-011: Complete command — CompleteReminderArgs parsing ===

        runTest("parseCompleteReminderArgs_valid") {
            let args = ["abc-123"]
            let result = CompleteReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc-123")
                assertFalse(parsed.useJSON, "Default should not use JSON")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseCompleteReminderArgs_withJSON") {
            let args = ["abc-123", "--json"]
            let result = CompleteReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc-123")
                assertTrue(parsed.useJSON, "Should enable JSON output")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseCompleteReminderArgs_missingId") {
            let args: [String] = []
            let result = CompleteReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing ID\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("identifiant"), "Error should mention missing ID: \(err.message)")
            }
        }

        // === US-012: Delete command — DeleteReminderArgs parsing ===

        runTest("parseDeleteReminderArgs_valid") {
            let args = ["def-456"]
            let result = DeleteReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "def-456")
                assertFalse(parsed.useJSON, "Default should not use JSON")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseDeleteReminderArgs_withJSON") {
            let args = ["def-456", "--json"]
            let result = DeleteReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "def-456")
                assertTrue(parsed.useJSON, "Should enable JSON output")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseDeleteReminderArgs_missingId") {
            let args: [String] = []
            let result = DeleteReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing ID\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("identifiant"), "Error should mention missing ID: \(err.message)")
            }
        }

        // === JSON formatter for complete/delete confirmation ===

        runTest("formatCompletedReminderJSON") {
            let result = CKReminderActionResult(id: "r-done", title: "Tache finie", action: "completed")
            let json = JSONFormatter.format(result)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["id"] as? String ?? "", "r-done")
            assertEqual(parsed["title"] as? String ?? "", "Tache finie")
            assertEqual(parsed["action"] as? String ?? "", "completed")
        }

        runTest("formatDeletedReminderJSON") {
            let result = CKReminderActionResult(id: "r-del", title: "Tache supprimee", action: "deleted")
            let json = JSONFormatter.format(result)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["id"] as? String ?? "", "r-del")
            assertEqual(parsed["title"] as? String ?? "", "Tache supprimee")
            assertEqual(parsed["action"] as? String ?? "", "deleted")
        }

        // === Due-before date filtering logic ===

        runTest("dueBefore_filter_includesBeforeDate") {
            // A reminder due on 2026-03-20 should be included when due-before is 2026-04-01
            let dueDate = "2026-03-20T10:00:00+01:00"
            let cutoffStr = "2026-04-01"
            guard let cutoff = EventDateParser.parseDate(cutoffStr) else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] could not parse cutoff date\n".utf8))
                return
            }
            // Simulate: parse the due date, check if before cutoff
            let dateOnly = EventDateParser.extractDate(dueDate)
            guard let reminderDate = EventDateParser.parseDate(dateOnly) else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] could not parse reminder date\n".utf8))
                return
            }
            assertTrue(reminderDate < cutoff, "Reminder date should be before cutoff")
        }

        runTest("dueBefore_filter_excludesAfterDate") {
            let dueDate = "2026-05-15T14:00:00+01:00"
            let cutoffStr = "2026-04-01"
            guard let cutoff = EventDateParser.parseDate(cutoffStr) else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] could not parse cutoff date\n".utf8))
                return
            }
            let dateOnly = EventDateParser.extractDate(dueDate)
            guard let reminderDate = EventDateParser.parseDate(dateOnly) else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] could not parse reminder date\n".utf8))
                return
            }
            assertFalse(reminderDate < cutoff, "Reminder date should NOT be before cutoff")
        }

        reportResults()
    }
}
