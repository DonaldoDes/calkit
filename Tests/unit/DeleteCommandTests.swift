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
