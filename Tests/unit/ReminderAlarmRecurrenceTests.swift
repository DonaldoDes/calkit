import Foundation
import EventKit

@main
struct ReminderAlarmRecurrenceTestRunner {
    static func main() {

        // ============================================================
        // 1. CKReminder model — alarms and recurrenceRules in JSON
        // ============================================================

        runTest("CKReminder_JSON_includes_alarms_when_present") {
            let reminder = CKReminder(
                id: "r-001", title: "Test", list: "Courses", listId: "l1",
                isCompleted: false, priority: 0, dueDate: nil, notes: nil,
                creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil,
                alarms: ["2026-03-25T09:00:00+01:00", "2026-03-25T08:30:00+01:00"],
                recurrenceRules: nil
            )
            let json = JSONFormatter.format(reminder)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON\n".utf8))
                return
            }
            guard let alarms = parsed["alarms"] as? [String] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] alarms key should be present as array\n".utf8))
                return
            }
            assertEqual(alarms.count, 2, "Should have 2 alarms")
            assertEqual(alarms[0], "2026-03-25T09:00:00+01:00")
            assertEqual(alarms[1], "2026-03-25T08:30:00+01:00")
        }

        runTest("CKReminder_JSON_alarms_null_when_nil") {
            let reminder = CKReminder(
                id: "r-002", title: "Test", list: "Courses", listId: "l1",
                isCompleted: false, priority: 0, dueDate: nil, notes: nil,
                creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil,
                alarms: nil,
                recurrenceRules: nil
            )
            let json = JSONFormatter.format(reminder)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON\n".utf8))
                return
            }
            // When nil, field should be null or absent
            let hasAlarms = parsed.keys.contains("alarms")
            if hasAlarms {
                assertTrue(parsed["alarms"] is NSNull, "alarms should be null when nil")
            }
            // Either absent or null is acceptable
        }

        runTest("CKReminder_JSON_includes_recurrenceRules_when_present") {
            let reminder = CKReminder(
                id: "r-003", title: "Daily task", list: "Travail", listId: "l2",
                isCompleted: false, priority: 1, dueDate: "2026-03-25T10:00:00+01:00", notes: nil,
                creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil,
                alarms: nil,
                recurrenceRules: ["FREQ=DAILY", "FREQ=WEEKLY;BYDAY=MO,WE,FR"]
            )
            let json = JSONFormatter.format(reminder)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON\n".utf8))
                return
            }
            guard let rules = parsed["recurrenceRules"] as? [String] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] recurrenceRules key should be present as array\n".utf8))
                return
            }
            assertEqual(rules.count, 2, "Should have 2 recurrence rules")
            assertEqual(rules[0], "FREQ=DAILY")
            assertEqual(rules[1], "FREQ=WEEKLY;BYDAY=MO,WE,FR")
        }

        runTest("CKReminder_JSON_both_alarms_and_recurrenceRules") {
            let reminder = CKReminder(
                id: "r-004", title: "Recurring with alarm", list: "Travail", listId: "l2",
                isCompleted: false, priority: 0, dueDate: "2026-03-25T10:00:00+01:00", notes: nil,
                creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil,
                alarms: ["2026-03-25T09:30:00+01:00"],
                recurrenceRules: ["FREQ=WEEKLY"]
            )
            let json = JSONFormatter.format(reminder)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON\n".utf8))
                return
            }
            assertTrue(parsed["alarms"] is [String], "alarms should be present")
            assertTrue(parsed["recurrenceRules"] is [String], "recurrenceRules should be present")
        }

        // ============================================================
        // 2. CreateReminderArgs — --alarm and --recurrence parsing
        // ============================================================

        runTest("CreateReminderArgs_parses_alarm_option") {
            let args = ["Test alarm", "--alarm", "2026-04-01T09:00:00"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Test alarm")
                assertEqual(parsed.alarm ?? "", "2026-04-01T09:00:00")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("CreateReminderArgs_parses_recurrence_option") {
            let args = ["Daily standup", "--recurrence", "FREQ=DAILY"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Daily standup")
                assertEqual(parsed.recurrence ?? "", "FREQ=DAILY")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("CreateReminderArgs_parses_alarm_and_recurrence_together") {
            let args = ["Weekly review", "--alarm", "2026-04-01T08:00:00", "--recurrence", "FREQ=WEEKLY", "--due", "2026-04-01T09:00:00"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.title, "Weekly review")
                assertEqual(parsed.alarm ?? "", "2026-04-01T08:00:00")
                assertEqual(parsed.recurrence ?? "", "FREQ=WEEKLY")
                assertEqual(parsed.dueDate ?? "", "2026-04-01T09:00:00")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("CreateReminderArgs_alarm_nil_when_not_provided") {
            let args = ["Simple task"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertTrue(parsed.alarm == nil, "alarm should be nil when not specified")
                assertTrue(parsed.recurrence == nil, "recurrence should be nil when not specified")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("CreateReminderArgs_invalid_alarm_date_rejected") {
            let args = ["Test", "--alarm", "not-a-date"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid alarm date\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("alarm") || err.message.contains("date"),
                           "Error should mention alarm or date: \(err.message)")
            }
        }

        runTest("CreateReminderArgs_invalid_recurrence_rejected") {
            let args = ["Test", "--recurrence", "INVALID"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for invalid recurrence rule\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("récurrence") || err.message.contains("recurrence"),
                           "Error should mention recurrence: \(err.message)")
            }
        }

        runTest("CreateReminderArgs_alarm_missing_value_rejected") {
            let args = ["Test", "--alarm"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for option without value\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("--alarm"), "Error should mention the option: \(err.message)")
            }
        }

        runTest("CreateReminderArgs_recurrence_missing_value_rejected") {
            let args = ["Test", "--recurrence"]
            let result = CreateReminderArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for option without value\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("--recurrence"), "Error should mention the option: \(err.message)")
            }
        }

        // ============================================================
        // 3. RecurrenceParser.format() — EKRecurrenceRule to RRULE string
        // ============================================================

        runTest("RecurrenceParser_format_daily") {
            let rule = RecurrenceParser.parse("FREQ=DAILY")
            guard let rule = rule else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] parse should succeed\n".utf8))
                return
            }
            let formatted = RecurrenceParser.format(rule)
            assertEqual(formatted, "FREQ=DAILY")
        }

        runTest("RecurrenceParser_format_weekly") {
            let rule = RecurrenceParser.parse("FREQ=WEEKLY")
            guard let rule = rule else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] parse should succeed\n".utf8))
                return
            }
            let formatted = RecurrenceParser.format(rule)
            assertEqual(formatted, "FREQ=WEEKLY")
        }

        runTest("RecurrenceParser_format_weekly_with_days") {
            let rule = RecurrenceParser.parse("FREQ=WEEKLY;BYDAY=MO,WE,FR")
            guard let rule = rule else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] parse should succeed\n".utf8))
                return
            }
            let formatted = RecurrenceParser.format(rule)
            assertEqual(formatted, "FREQ=WEEKLY;BYDAY=MO,WE,FR")
        }

        runTest("RecurrenceParser_format_monthly") {
            let rule = RecurrenceParser.parse("FREQ=MONTHLY")
            guard let rule = rule else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] parse should succeed\n".utf8))
                return
            }
            let formatted = RecurrenceParser.format(rule)
            assertEqual(formatted, "FREQ=MONTHLY")
        }

        runTest("RecurrenceParser_format_yearly") {
            let rule = RecurrenceParser.parse("FREQ=YEARLY")
            guard let rule = rule else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] parse should succeed\n".utf8))
                return
            }
            let formatted = RecurrenceParser.format(rule)
            assertEqual(formatted, "FREQ=YEARLY")
        }

        // ============================================================
        // 4. Existing CKReminder test compat — old initializer still works
        // ============================================================

        runTest("CKReminder_backward_compat_formatReminders_still_works") {
            // Tests that old format functions still work with reminders that have alarms/recurrence
            let reminders = [
                CKReminder(id: "r-010", title: "With extras", list: "Travail", listId: "l1",
                           isCompleted: false, priority: 1, dueDate: "2026-04-01T10:00:00+01:00", notes: nil,
                           creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil,
                           alarms: ["2026-04-01T09:30:00+01:00"],
                           recurrenceRules: ["FREQ=DAILY"])
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("With extras"), "Should contain title")
            assertTrue(output.contains("r-010"), "Should contain id")
        }

        reportResults()
    }
}
