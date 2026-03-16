import Foundation
import EventKit

// Minimal test framework for standalone swiftc compilation (no XCTest dependency)
var testCount = 0
var failCount = 0
var currentTest = ""

func runTest(_ name: String, _ body: () -> Void) {
    currentTest = name
    testCount += 1
    body()
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "", file: String = #file, line: Int = #line) {
    if a != b {
        failCount += 1
        let extra = msg.isEmpty ? "" : " — \(msg)"
        FileHandle.standardError.write(Data("FAIL [\(currentTest)] \(file):\(line): \(a) != \(b)\(extra)\n".utf8))
    }
}

func assertTrue(_ condition: Bool, _ msg: String = "", file: String = #file, line: Int = #line) {
    if !condition {
        failCount += 1
        let extra = msg.isEmpty ? "" : " — \(msg)"
        FileHandle.standardError.write(Data("FAIL [\(currentTest)] \(file):\(line): assertion false\(extra)\n".utf8))
    }
}

func assertFalse(_ condition: Bool, _ msg: String = "", file: String = #file, line: Int = #line) {
    assertTrue(!condition, msg, file: file, line: line)
}

@main
struct UpdateTestRunner {
    static func main() {

        // --- Argument Parsing Tests ---

        runTest("testParseUpdateArgs_valid") {
            let args = ["abc123", "--title", "Réunion modifiée", "--start", "2026-03-20T15:00:00",
                        "--end", "2026-03-20T16:00:00", "--location", "Salle B", "--notes", "Nouveau contenu"]
            let result = UpdateEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc123")
                assertEqual(parsed.title ?? "", "Réunion modifiée")
                assertEqual(parsed.startStr ?? "", "2026-03-20T15:00:00")
                assertEqual(parsed.endStr ?? "", "2026-03-20T16:00:00")
                assertEqual(parsed.location ?? "", "Salle B")
                assertEqual(parsed.notes ?? "", "Nouveau contenu")
                assertFalse(parsed.useJSON)
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseUpdateArgs_missingId") {
            // No positional args at all — only options
            let args = ["--title", "Test"]
            let result = UpdateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing ID\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("ID") || err.message.contains("id") || err.message.contains("identifiant"),
                           "Error should mention missing ID: \(err.message)")
            }
        }

        runTest("testParseUpdateArgs_noFields") {
            // ID present but no fields to update
            let args = ["abc123"]
            let result = UpdateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed when no fields provided\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("champ") || err.message.contains("modifier") || err.message.contains("option"),
                           "Error should mention no fields to update: \(err.message)")
            }
        }

        runTest("testParseUpdateArgs_invalidDate") {
            let args = ["abc123", "--start", "not-a-date"]
            let result = UpdateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid date\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("invalide"),
                           "Error should mention invalid date: \(err.message)")
            }
        }

        // --- Output Formatting Tests ---

        runTest("testFormatUpdatedEventText") {
            let event = CKEvent(
                id: "abc123", title: "Réunion équipe (modifié)",
                start: "2026-03-20T15:00:00+01:00", end: "2026-03-20T16:00:00+01:00",
                calendar: "Travail", calendarId: "def456",
                location: "", notes: "", isAllDay: false, url: ""
            )
            let output = TextFormatter.formatUpdatedEvent(event)
            assertTrue(output.hasPrefix("Événement mis à jour."), "Should start with update confirmation")
            assertTrue(output.contains("abc123"), "Should contain event ID")
            assertTrue(output.contains("Réunion équipe (modifié)"), "Should contain updated title")
            assertTrue(output.contains("2026-03-20T15:00:00+01:00"), "Should contain start date")
            assertTrue(output.contains("2026-03-20T16:00:00+01:00"), "Should contain end date")
            assertTrue(output.contains("Travail"), "Should contain calendar name")
        }

        runTest("testFormatUpdatedEventJSON") {
            let event = CKEvent(
                id: "abc123", title: "Réunion équipe (modifié)",
                start: "2026-03-20T15:00:00+01:00", end: "2026-03-20T16:00:00+01:00",
                calendar: "Travail", calendarId: "def456",
                location: "Salle B", notes: "Nouveau", isAllDay: false, url: ""
            )
            let json = JSONFormatter.format(event)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["id"] as? String ?? "", "abc123")
            assertEqual(parsed["title"] as? String ?? "", "Réunion équipe (modifié)")
            assertEqual(parsed["start"] as? String ?? "", "2026-03-20T15:00:00+01:00")
            assertEqual(parsed["end"] as? String ?? "", "2026-03-20T16:00:00+01:00")
            assertEqual(parsed["calendar"] as? String ?? "", "Travail")
            assertEqual(parsed["location"] as? String ?? "", "Salle B")
            assertEqual(parsed["notes"] as? String ?? "", "Nouveau")
        }

        // Report
        print("")
        if failCount > 0 {
            print("\(failCount) failure(s) out of \(testCount) tests.")
            exit(1)
        } else {
            print("All \(testCount) tests passed.")
            exit(0)
        }
    }
}
