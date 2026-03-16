import Foundation
import EventKit

@main
struct CreateTestRunner {
    static func main() {

        // --- Argument Parsing Tests ---

        runTest("testParseCreateArgs_valid") {
            let args = ["Réunion équipe", "--start", "2026-03-20T14:00:00", "--end", "2026-03-20T15:00:00",
                        "--calendar", "Travail", "--location", "Salle A", "--notes", "Agenda: roadmap",
                        "--recurrence", "FREQ=WEEKLY;BYDAY=MO,WE"]
            let result = CreateEventArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Réunion équipe")
                assertEqual(parsed.startStr, "2026-03-20T14:00:00")
                assertEqual(parsed.endStr, "2026-03-20T15:00:00")
                assertEqual(parsed.calendarName ?? "", "Travail")
                assertEqual(parsed.location ?? "", "Salle A")
                assertEqual(parsed.notes ?? "", "Agenda: roadmap")
                assertEqual(parsed.recurrence ?? "", "FREQ=WEEKLY;BYDAY=MO,WE")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err)\n".utf8))
            }
        }

        runTest("testParseCreateArgs_missingStart") {
            let args = ["Réunion", "--end", "2026-03-20T15:00:00"]
            let result = CreateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing --start\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("--start"), "Error should mention --start: \(err.message)")
            }
        }

        runTest("testParseCreateArgs_missingEnd") {
            let args = ["Réunion", "--start", "2026-03-20T14:00:00"]
            let result = CreateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing --end\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("--end"), "Error should mention --end: \(err.message)")
            }
        }

        runTest("testParseCreateArgs_invalidDate") {
            let args = ["Réunion", "--start", "not-a-date", "--end", "2026-03-20T15:00:00"]
            let result = CreateEventArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid date\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("invalide"), "Error should mention invalid date: \(err.message)")
            }
        }

        // --- Output Formatting Tests ---

        runTest("testFormatCreatedEventText") {
            let event = CKEvent(
                id: "abc123", title: "Réunion équipe",
                start: "2026-03-20T14:00:00+01:00", end: "2026-03-20T15:00:00+01:00",
                calendar: "Travail", calendarId: "def456",
                location: "", notes: "", isAllDay: false, url: ""
            )
            let output = TextFormatter.formatCreatedEvent(event)
            assertTrue(output.contains("abc123"), "Should contain event ID")
            assertTrue(output.contains("Réunion équipe"), "Should contain title")
            assertTrue(output.contains("2026-03-20T14:00:00+01:00"), "Should contain start date")
            assertTrue(output.contains("2026-03-20T15:00:00+01:00"), "Should contain end date")
            assertTrue(output.contains("Travail"), "Should contain calendar name")
            assertTrue(output.hasPrefix("Événement créé."), "Should start with confirmation message")
        }

        runTest("testFormatCreatedEventJSON") {
            let event = CKEvent(
                id: "abc123", title: "Réunion équipe",
                start: "2026-03-20T14:00:00+01:00", end: "2026-03-20T15:00:00+01:00",
                calendar: "Travail", calendarId: "def456",
                location: "Salle A", notes: "Agenda", isAllDay: false, url: ""
            )
            let json = JSONFormatter.format(event)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["id"] as? String ?? "", "abc123")
            assertEqual(parsed["title"] as? String ?? "", "Réunion équipe")
            assertEqual(parsed["start"] as? String ?? "", "2026-03-20T14:00:00+01:00")
            assertEqual(parsed["end"] as? String ?? "", "2026-03-20T15:00:00+01:00")
            assertEqual(parsed["calendar"] as? String ?? "", "Travail")
            assertEqual(parsed["calendarId"] as? String ?? "", "def456")
            assertEqual(parsed["location"] as? String ?? "", "Salle A")
            assertEqual(parsed["notes"] as? String ?? "", "Agenda")
            assertEqual(parsed["isAllDay"] as? Bool ?? true, false)
            assertTrue(parsed.keys.contains("url"), "Should contain url field")
        }

        // --- Recurrence Parsing Tests ---

        runTest("testParseRecurrenceDaily") {
            let rule = RecurrenceParser.parse("FREQ=DAILY")
            assertTrue(rule != nil, "Should parse FREQ=DAILY")
            if let rule = rule {
                assertEqual(rule.frequency, EKRecurrenceFrequency.daily)
                assertEqual(rule.interval, 1)
                assertTrue(rule.daysOfTheWeek == nil || rule.daysOfTheWeek!.isEmpty,
                           "Daily should have no specific days")
            }
        }

        runTest("testParseRecurrenceWeekly") {
            let rule = RecurrenceParser.parse("FREQ=WEEKLY;BYDAY=MO,WE")
            assertTrue(rule != nil, "Should parse FREQ=WEEKLY;BYDAY=MO,WE")
            if let rule = rule {
                assertEqual(rule.frequency, EKRecurrenceFrequency.weekly)
                assertEqual(rule.interval, 1)
                assertTrue(rule.daysOfTheWeek != nil, "Weekly with BYDAY should have days")
                if let days = rule.daysOfTheWeek {
                    assertEqual(days.count, 2, "Should have 2 days")
                    let dayNumbers = days.map { $0.dayOfTheWeek.rawValue }.sorted()
                    assertTrue(dayNumbers.contains(EKWeekday.monday.rawValue), "Should contain Monday")
                    assertTrue(dayNumbers.contains(EKWeekday.wednesday.rawValue), "Should contain Wednesday")
                }
            }
        }

        reportResults()
    }
}
