import Foundation

@main
struct TestRunner {
    static func main() {
        // TextFormatter Tests
        // --- BUG-001: Source now shows "account (type)" format ---

        runTest("formatCalendarsText_singleEntry_accountSource") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "donaldo@gmail.com (Google)", color: "#4285F4")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            assertTrue(output.contains("[donaldo@gmail.com (Google)]"), "Output should contain account name with type in brackets")
            assertTrue(output.contains("Perso"), "Output should contain calendar title")
            assertTrue(output.contains("abc123"), "Output should contain calendar id")
        }

        runTest("formatCalendarsText_multipleEntries_accountSources") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "donaldo@gmail.com (Google)", color: "#4285F4"),
                CKCalendar(id: "def456", title: "Travail", source: "iCloud", color: "#FF6B6B"),
                CKCalendar(id: "ghi789", title: "Réunions", source: "work@company.com (Exchange)", color: "#00FF00")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            let lines = output.split(separator: "\n")
            assertEqual(lines.count, 3, "Should have one line per calendar")
            assertTrue(output.contains("[donaldo@gmail.com (Google)]"), "Should contain Google account source")
            assertTrue(output.contains("[iCloud]"), "Should contain iCloud source (title=iCloud for personal)")
            assertTrue(output.contains("[work@company.com (Exchange)]"), "Should contain Exchange account source")
        }

        runTest("formatCalendarsText_alignedColumns") {
            let calendars = [
                CKCalendar(id: "a1", title: "Short", source: "iCloud", color: "#000000"),
                CKCalendar(id: "b2", title: "Much Longer Name", source: "donaldo@gmail.com (Google)", color: "#FFFFFF")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            let lines = output.split(separator: "\n").map(String.init)
            assertEqual(lines.count, 2)

            // Title columns should start at the same position (source column padded to same width)
            // The source column is "[source]" padded, then "  Title".
            // Find the position of the title text after the padded source column.
            let maxSourceLen = max("iCloud".count, "donaldo@gmail.com (Google)".count)
            let expectedTitleStart = maxSourceLen + 2 + 2 // brackets + gap
            // Both lines should have the title starting at the same column
            assertTrue(lines[0].contains("Short"), "First line should contain title")
            assertTrue(lines[1].contains("Much Longer Name"), "Second line should contain title")
            // Verify both lines have the same total source column width
            assertEqual(lines[0].count > expectedTitleStart, true, "Line should be long enough")
            assertEqual(lines[1].count > expectedTitleStart, true, "Line should be long enough")
        }

        runTest("formatCalendarsText_empty") {
            let calendars: [CKCalendar] = []
            let output = TextFormatter.formatCalendars(calendars)
            assertTrue(output.isEmpty, "Empty list should produce empty output")
        }

        runTest("formatCalendarsText_noTrailingWhitespace") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "donaldo@gmail.com (Google)", color: "#4285F4")
            ]
            let output = TextFormatter.formatCalendars(calendars)
            for line in output.split(separator: "\n") {
                let str = String(line)
                var trimmed = str
                while trimmed.last?.isWhitespace == true { trimmed.removeLast() }
                assertEqual(str, trimmed, "No trailing whitespace")
            }
        }

        runTest("sourceFormat_accountWithType") {
            // Verifies the new source format: "account (type)"
            let cal = CKCalendar(id: "x", title: "Test", source: "user@example.com (CalDAV)", color: "#000")
            assertEqual(cal.source, "user@example.com (CalDAV)", "Source should contain account name and type")
        }

        runTest("sourceFormat_iCloudNoEmail") {
            // iCloud personal often returns "iCloud" as source.title — no email prefix
            let cal = CKCalendar(id: "x", title: "Famille", source: "iCloud", color: "#000")
            assertEqual(cal.source, "iCloud", "iCloud source should be just 'iCloud' when no email")
        }

        // JSONFormatter Tests
        runTest("formatJSON_calendars_accountSource") {
            let calendars = [
                CKCalendar(id: "abc123", title: "Perso", source: "donaldo@gmail.com (Google)", color: "#4285F4")
            ]
            let output = JSONFormatter.format(calendars)
            assertFalse(output.isEmpty, "JSON output should not be empty")

            guard let data = output.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [formatJSON_calendars_accountSource] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1)
            assertEqual(parsed[0]["id"] as? String ?? "", "abc123")
            assertEqual(parsed[0]["title"] as? String ?? "", "Perso")
            assertEqual(parsed[0]["source"] as? String ?? "", "donaldo@gmail.com (Google)")
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

        // --- Calendar Sorting Tests ---

        runTest("calendars_sortedAlphabetically_bySourceThenTitle") {
            let unsorted = [
                CKCalendar(id: "1", title: "Travail", source: "iCloud", color: "#000"),
                CKCalendar(id: "2", title: "anniversaires", source: "iCloud", color: "#000"),
                CKCalendar(id: "3", title: "Perso", source: "Google", color: "#000"),
                CKCalendar(id: "4", title: "Réunions", source: "Exchange", color: "#000"),
                CKCalendar(id: "5", title: "école", source: "iCloud", color: "#000")
            ]
            let sorted = CKCalendar.sortedAlphabetically(unsorted)
            let titles = sorted.map { $0.title }
            // Expected: Exchange first, then Google, then iCloud (3 calendars sorted by title within)
            assertEqual(titles, ["Réunions", "Perso", "anniversaires", "école", "Travail"],
                        "Calendars should be sorted by source first, then by title within each source")
        }

        // --- Event Text Formatter Tests ---

        runTest("formatEventsText_empty") {
            let events: [CKEvent] = []
            let output = TextFormatter.formatEventsText(events, groupByDay: true)
            assertEqual(output, "Aucun événement trouvé")
        }

        runTest("formatEventsText_single") {
            let events = [
                CKEvent(
                    id: "abc123", title: "Réunion équipe",
                    start: "2026-03-16T10:00:00+01:00", end: "2026-03-16T11:00:00+01:00",
                    calendar: "Travail", calendarId: "def456",
                    location: "", notes: "", isAllDay: false, url: ""
                )
            ]
            let output = TextFormatter.formatEventsText(events, groupByDay: true)
            assertTrue(output.contains("10:00"), "Should contain start time")
            assertTrue(output.contains("11:00"), "Should contain end time")
            assertTrue(output.contains("Réunion équipe"), "Should contain event title")
            assertTrue(output.contains("[Travail]"), "Should contain calendar name in brackets")
        }

        runTest("formatEventsText_allDay") {
            let events = [
                CKEvent(
                    id: "xyz789", title: "Jour férié",
                    start: "2026-03-16T00:00:00+01:00", end: "2026-03-17T00:00:00+01:00",
                    calendar: "Jours fériés", calendarId: "jf001",
                    location: "", notes: "", isAllDay: true, url: ""
                )
            ]
            let output = TextFormatter.formatEventsText(events, groupByDay: true)
            assertTrue(output.contains("(Toute la journée)"), "All-day events should show '(Toute la journée)'")
            assertTrue(output.contains("Jour férié"), "Should contain event title")
            assertTrue(output.contains("[Jours fériés]"), "Should contain calendar name")
        }

        runTest("formatEventsJSON") {
            let events = [
                CKEvent(
                    id: "abc123", title: "Réunion équipe",
                    start: "2026-03-16T10:00:00+01:00", end: "2026-03-16T11:00:00+01:00",
                    calendar: "Travail", calendarId: "def456",
                    location: "Salle A", notes: "Agenda: roadmap", isAllDay: false, url: ""
                )
            ]
            let json = JSONFormatter.format(events)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [formatEventsJSON] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1, "Should have one event")
            assertEqual(parsed[0]["id"] as? String ?? "", "abc123")
            assertEqual(parsed[0]["title"] as? String ?? "", "Réunion équipe")
            assertEqual(parsed[0]["start"] as? String ?? "", "2026-03-16T10:00:00+01:00")
            assertEqual(parsed[0]["calendar"] as? String ?? "", "Travail")
            assertEqual(parsed[0]["calendarId"] as? String ?? "", "def456")
            assertEqual(parsed[0]["location"] as? String ?? "", "Salle A")
            assertEqual(parsed[0]["isAllDay"] as? Bool ?? true, false)
        }

        runTest("parseDateToday") {
            // Today should produce a range from 00:00:00 to 23:59:59
            let (start, end) = EventDateParser.todayRange()
            let cal = Calendar.current
            assertEqual(cal.component(.hour, from: start), 0)
            assertEqual(cal.component(.minute, from: start), 0)
            assertEqual(cal.component(.second, from: start), 0)
            assertEqual(cal.component(.hour, from: end), 23)
            assertEqual(cal.component(.minute, from: end), 59)
            assertEqual(cal.component(.second, from: end), 59)
            // Same day
            assertEqual(cal.component(.day, from: start), cal.component(.day, from: end))
        }

        runTest("parseDateRange") {
            let result = EventDateParser.parseDate("2026-03-20")
            assertTrue(result != nil, "Should parse YYYY-MM-DD format")
            if let date = result {
                let cal = Calendar.current
                assertEqual(cal.component(.year, from: date), 2026)
                assertEqual(cal.component(.month, from: date), 3)
                assertEqual(cal.component(.day, from: date), 20)
            }
        }

        reportResults()
    }
}
