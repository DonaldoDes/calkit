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
struct TestRunner {
    static func main() {
        // TextFormatter Tests
        runTest("formatCalendarsText_singleEntry") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "Google", color: "#4285F4")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            assertTrue(output.contains("[Google]"), "Output should contain source in brackets")
            assertTrue(output.contains("Perso"), "Output should contain calendar title")
            assertTrue(output.contains("abc123"), "Output should contain calendar id")
        }

        runTest("formatCalendarsText_multipleEntries") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "Google", color: "#4285F4"),
                CKCalendar(id: "def456", title: "Travail", source: "iCloud", color: "#FF6B6B"),
                CKCalendar(id: "ghi789", title: "Réunions", source: "Exchange", color: "#00FF00")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            let lines = output.split(separator: "\n")
            assertEqual(lines.count, 3, "Should have one line per calendar")
            assertTrue(output.contains("[Google]"), "Should contain Google source")
            assertTrue(output.contains("[iCloud]"), "Should contain iCloud source")
            assertTrue(output.contains("[Exchange]"), "Should contain Exchange source")
        }

        runTest("formatCalendarsText_alignedColumns") {
            let calendars = [
                CKCalendar(id: "a1", title: "Short", source: "iCloud", color: "#000000"),
                CKCalendar(id: "b2", title: "Much Longer Name", source: "Google", color: "#FFFFFF")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            let lines = output.split(separator: "\n").map(String.init)
            assertEqual(lines.count, 2)

            // Source columns should be aligned (padded to same width)
            let firstBracketEnd = lines[0].range(of: "]")!.upperBound
            let secondBracketEnd = lines[1].range(of: "]")!.upperBound
            let firstOffset = lines[0].distance(from: lines[0].startIndex, to: firstBracketEnd)
            let secondOffset = lines[1].distance(from: lines[1].startIndex, to: secondBracketEnd)
            assertEqual(firstOffset, secondOffset, "Source columns should be aligned")
        }

        runTest("formatCalendarsText_empty") {
            let calendars: [CKCalendar] = []
            let output = TextFormatter.formatCalendars(calendars)
            assertTrue(output.isEmpty, "Empty list should produce empty output")
        }

        runTest("formatCalendarsText_noTrailingWhitespace") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "Google", color: "#4285F4")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            for line in output.split(separator: "\n") {
                let str = String(line)
                var trimmed = str
                while trimmed.last?.isWhitespace == true { trimmed.removeLast() }
                assertEqual(str, trimmed, "No trailing whitespace")
            }
        }

        // JSONFormatter Tests
        runTest("formatJSON_calendars") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "Google", color: "#4285F4")
            ]
            let output = JSONFormatter.format(calendars)
            assertFalse(output.isEmpty, "JSON output should not be empty")

            guard let data = output.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [formatJSON_calendars] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1)
            assertEqual(parsed[0]["id"] as? String ?? "", "abc123")
            assertEqual(parsed[0]["title"] as? String ?? "", "Perso")
            assertEqual(parsed[0]["source"] as? String ?? "", "Google")
            assertEqual(parsed[0]["color"] as? String ?? "", "#4285F4")
        }

        runTest("formatJSON_prettyPrinted") {
            let calendars = [
                CKCalendar(id: "x", title: "Test", source: "Local", color: "#000000")
            ]
            let output = JSONFormatter.format(calendars)
            assertTrue(output.contains("\n"), "Pretty printed JSON should contain newlines")
        }

        runTest("formatJSON_empty") {
            let calendars: [CKCalendar] = []
            let output = JSONFormatter.format(calendars)
            guard let data = output.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [formatJSON_empty] Empty array should be valid JSON\n".utf8))
                return
            }
            assertTrue(parsed.isEmpty)
        }

        // Hex Color Tests
        runTest("hexFromRGB_knownColors") {
            let red = EventKitService.hexFromRGB(r: 1.0, g: 0.0, b: 0.0)
            assertEqual(red, "#FF0000")

            let white = EventKitService.hexFromRGB(r: 1.0, g: 1.0, b: 1.0)
            assertEqual(white, "#FFFFFF")

            let black = EventKitService.hexFromRGB(r: 0.0, g: 0.0, b: 0.0)
            assertEqual(black, "#000000")
        }

        runTest("hexFromRGB_midValues") {
            let mid = EventKitService.hexFromRGB(r: 0.5, g: 0.5, b: 0.5)
            assertEqual(mid, "#808080", "0.5 should map to 0x80 (128)")
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
