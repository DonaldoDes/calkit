import Foundation

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
struct SearchTestRunner {
    static func main() {

        // --- Search Formatter Tests ---

        runTest("testFormatSearchResults_empty") {
            let results: [(event: CKEvent, matchedOn: String)] = []
            let output = TextFormatter.formatSearchResultsText(results, term: "foo")
            assertEqual(output, "Aucun résultat pour 'foo'")
        }

        runTest("testFormatSearchResults_matchTitle") {
            let event = CKEvent(
                id: "e1", title: "Réunion équipe",
                start: "2026-03-16T10:00:00+01:00", end: "2026-03-16T11:00:00+01:00",
                calendar: "Travail", calendarId: "c1",
                location: "", notes: "", isAllDay: false, url: ""
            )
            let results: [(event: CKEvent, matchedOn: String)] = [(event: event, matchedOn: "title")]
            let output = TextFormatter.formatSearchResultsText(results, term: "réunion")
            assertTrue(output.contains("[match: title]"), "Should contain match indicator for title")
            assertTrue(output.contains("Réunion équipe"), "Should contain event title")
            assertTrue(output.contains("[Travail]"), "Should contain calendar name")
        }

        runTest("testFormatSearchResults_matchNotes") {
            let event = CKEvent(
                id: "e2", title: "Standup",
                start: "2026-03-16T09:00:00+01:00", end: "2026-03-16T09:30:00+01:00",
                calendar: "Travail", calendarId: "c1",
                location: "", notes: "Discussion roadmap produit", isAllDay: false, url: ""
            )
            let results: [(event: CKEvent, matchedOn: String)] = [(event: event, matchedOn: "notes")]
            let output = TextFormatter.formatSearchResultsText(results, term: "roadmap")
            assertTrue(output.contains("[match: notes]"), "Should contain match indicator for notes")
            assertTrue(output.contains("Standup"), "Should contain event title")
        }

        runTest("testFormatSearchResults_matchBoth") {
            let event = CKEvent(
                id: "e3", title: "Planning sprint",
                start: "2026-03-17T14:00:00+01:00", end: "2026-03-17T15:00:00+01:00",
                calendar: "Travail", calendarId: "c1",
                location: "", notes: "Revoir le planning", isAllDay: false, url: ""
            )
            let results: [(event: CKEvent, matchedOn: String)] = [(event: event, matchedOn: "title,notes")]
            let output = TextFormatter.formatSearchResultsText(results, term: "planning")
            assertTrue(output.contains("[match: title,notes]"), "Should contain match indicator for both")
            assertTrue(output.contains("Planning sprint"), "Should contain event title")
        }

        runTest("testSearchResultJSON") {
            let searchResult = CKSearchResult(
                id: "e1", title: "Réunion équipe",
                start: "2026-03-16T10:00:00+01:00", end: "2026-03-16T11:00:00+01:00",
                calendar: "Travail", calendarId: "c1",
                location: "Salle A", notes: "Agenda: roadmap",
                isAllDay: false, url: "", matchedOn: "title"
            )
            let json = JSONFormatter.format([searchResult])
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [testSearchResultJSON] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1, "Should have one search result")
            assertEqual(parsed[0]["matchedOn"] as? String ?? "", "title", "Should have matchedOn field")
            assertEqual(parsed[0]["id"] as? String ?? "", "e1")
            assertEqual(parsed[0]["title"] as? String ?? "", "Réunion équipe")
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
