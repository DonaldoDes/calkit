import Foundation
import EventKit

@main
struct DeleteTestRunner {
    static func main() {

        // --- Argument Parsing Tests ---

        runTest("testParseDeleteArgs_valid_default") {
            let args = ["abc123"]
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc123")
                assertEqual(parsed.span, "thisEvent", "Default span should be thisEvent")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseDeleteArgs_futureEvents") {
            let args = ["abc123", "--span", "futureEvents"]
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc123")
                assertEqual(parsed.span, "futureEvents")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseDeleteArgs_missingId") {
            let args: [String] = []
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing ID\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("ID") || err.message.contains("id") || err.message.contains("identifiant"),
                           "Error should mention missing ID: \(err.message)")
            }
        }

        runTest("testParseDeleteArgs_invalidSpan") {
            let args = ["abc123", "--span", "allEvents"]
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid span\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("span") || err.message.contains("thisEvent") || err.message.contains("futureEvents"),
                           "Error should mention valid span values: \(err.message)")
            }
        }

        runTest("testFormatDeletedEventText") {
            let output = TextFormatter.formatDeletedEvent(id: "abc123", title: "Reunion equipe", span: "thisEvent")
            assertTrue(output.hasPrefix("Evenement supprime.") || output.contains("supprim"),
                       "Should contain deletion confirmation: \(output)")
            assertTrue(output.contains("abc123"), "Should contain event ID")
            assertTrue(output.contains("Reunion equipe") || output.contains("quipe"),
                       "Should contain event title")
            assertTrue(output.contains("thisEvent"), "Should contain span value")
        }

        // --- Fix 5: --json flag tests ---

        runTest("testParseDeleteArgs_jsonFlag") {
            let args = ["abc123", "--json"]
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc123")
                assertEqual(parsed.span, "thisEvent")
                assertTrue(parsed.useJSON, "Should detect --json flag")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testParseDeleteArgs_jsonAndSpan") {
            let args = ["abc123", "--span", "futureEvents", "--json"]
            let result = DeleteEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.id, "abc123")
                assertEqual(parsed.span, "futureEvents")
                assertTrue(parsed.useJSON, "Should detect --json flag with --span")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("testFormatDeletedEventJSON") {
            let json = JSONFormatter.formatDeletedEvent(id: "abc123", title: "Reunion equipe", span: "thisEvent")
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["id"] as? String ?? "", "abc123")
            assertEqual(parsed["title"] as? String ?? "", "Reunion equipe")
            assertEqual(parsed["span"] as? String ?? "", "thisEvent")
            assertEqual(parsed["deleted"] as? Bool ?? false, true, "Should have deleted=true")
        }

        reportResults()
    }
}
