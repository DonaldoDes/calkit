import Foundation

@main
struct CreateReminderTestRunner {
    static func main() {

        // --- CreateReminderArgs Parsing Tests ---

        runTest("testParseCreateReminderArgs_titleOnly") {
            let args = ["Acheter du pain"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Acheter du pain")
                assertTrue(parsed.listName == nil, "List should be nil when not specified")
                assertTrue(parsed.dueDate == nil, "Due date should be nil when not specified")
                assertEqual(parsed.priority, 0, "Default priority should be 0")
                assertTrue(parsed.notes == nil, "Notes should be nil when not specified")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_allOptions") {
            let args = ["Appeler le médecin", "--list", "Perso", "--due", "2026-04-01T10:00:00",
                        "--priority", "1", "--notes", "RDV annuel"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Appeler le médecin")
                assertEqual(parsed.listName ?? "", "Perso")
                assertEqual(parsed.dueDate ?? "", "2026-04-01T10:00:00")
                assertEqual(parsed.priority, 1)
                assertEqual(parsed.notes ?? "", "RDV annuel")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_missingTitle") {
            let args: [String] = []
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing title\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("titre"), "Error should mention missing title: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_emptyTitle") {
            let args = [""]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for empty title\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("titre"), "Error should mention missing title: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_invalidPriority_tooHigh") {
            let args = ["Test", "--priority", "10"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for priority > 9\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("priorit"), "Error should mention priority: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_invalidPriority_notNumber") {
            let args = ["Test", "--priority", "abc"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for non-numeric priority\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("priorit"), "Error should mention priority: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_invalidDueDate") {
            let args = ["Test", "--due", "not-a-date"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid due date\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("date"), "Error should mention invalid date: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_optionMissingValue") {
            let args = ["Test", "--list"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for option without value\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("--list"), "Error should mention the option: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_priority_boundary_0") {
            let args = ["Test", "--priority", "0"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.priority, 0, "Priority 0 should be valid (none)")
            case .failure:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] priority 0 should be valid\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_priority_boundary_9") {
            let args = ["Test", "--priority", "9"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.priority, 9, "Priority 9 should be valid")
            case .failure:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] priority 9 should be valid\n".utf8))
            }
        }

        // --- Critical #2: useJSON flag support ---

        runTest("testParseCreateReminderArgs_useJSON_default_false") {
            let args = ["Acheter du pain"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertFalse(parsed.useJSON, "Default useJSON should be false")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_useJSON_flag") {
            let args = ["Acheter du pain", "--json"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertTrue(parsed.useJSON, "useJSON should be true when --json is passed")
                assertEqual(parsed.title, "Acheter du pain")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_useJSON_with_all_options") {
            let args = ["Appeler le médecin", "--list", "Perso", "--due", "2026-04-01T10:00:00",
                        "--priority", "1", "--notes", "RDV annuel", "--json"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertTrue(parsed.useJSON, "useJSON should be true when --json is passed with other options")
                assertEqual(parsed.title, "Appeler le médecin")
                assertEqual(parsed.listName ?? "", "Perso")
                assertEqual(parsed.priority, 1)
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_useJSON_position_independent") {
            let args = ["--json", "Ma tache", "--list", "Travail"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertTrue(parsed.useJSON, "useJSON should be true regardless of position")
                assertEqual(parsed.title, "Ma tache")
                assertEqual(parsed.listName ?? "", "Travail")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        // --- --url option parsing ---

        runTest("testParseCreateReminderArgs_withUrl") {
            let args = ["Buy milk", "--url", "https://example.com/task"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Buy milk")
                assertEqual(parsed.url ?? "", "https://example.com/task")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_urlDefault_nil") {
            let args = ["Simple task"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertTrue(parsed.url == nil, "URL should be nil when not specified")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseCreateReminderArgs_invalidUrl") {
            let args = ["Test", "--url", "not a valid url"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid URL\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("URL"), "Error should mention URL: \(err.message)")
            }
        }

        runTest("testParseCreateReminderArgs_urlWithAllOptions") {
            let args = ["Full task", "--list", "Work", "--due", "2026-04-01T10:00:00",
                        "--priority", "1", "--notes", "Details", "--url", "https://jira.example.com/TASK-42"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Full task")
                assertEqual(parsed.url ?? "", "https://jira.example.com/TASK-42")
                assertEqual(parsed.listName ?? "", "Work")
                assertEqual(parsed.priority, 1)
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        reportResults()
    }
}
