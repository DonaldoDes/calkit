import Foundation

@main
struct ReminderFormatterTestRunner {
    static func main() {

        // --- CKReminderList Text Formatting Tests ---

        runTest("formatReminderLists_single") {
            let lists = [
                CKReminderList(id: "list-001", title: "Courses", source: "iCloud", color: "#FF6B6B", pendingCount: 3)
            ]
            let output = TextFormatter.formatReminderLists(lists)
            assertTrue(output.contains("[iCloud]"), "Should contain source in brackets")
            assertTrue(output.contains("Courses"), "Should contain list title")
            assertTrue(output.contains("3"), "Should contain pending count")
            assertTrue(output.contains("list-001"), "Should contain list id")
        }

        runTest("formatReminderLists_multiple_aligned") {
            let lists = [
                CKReminderList(id: "l1", title: "Courses", source: "iCloud", color: "#FF6B6B", pendingCount: 3),
                CKReminderList(id: "l2", title: "Travail urgent", source: "Exchange", color: "#00FF00", pendingCount: 12),
                CKReminderList(id: "l3", title: "Perso", source: "donaldo@gmail.com (Google)", color: "#4285F4", pendingCount: 0)
            ]
            let output = TextFormatter.formatReminderLists(lists)
            let lines = output.split(separator: "\n")
            assertEqual(lines.count, 3, "Should have one line per list")
        }

        runTest("formatReminderLists_empty") {
            let lists: [CKReminderList] = []
            let output = TextFormatter.formatReminderLists(lists)
            assertTrue(output.isEmpty, "Empty list should produce empty output")
        }

        // --- CKReminder Text Formatting Tests ---

        runTest("formatReminders_single_noDueDate") {
            let reminders = [
                CKReminder(id: "r-001", title: "Acheter du pain", list: "Courses", listId: "l1",
                           isCompleted: false, priority: 0, dueDate: nil, notes: nil, creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil)
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("Acheter du pain"), "Should contain reminder title")
            assertTrue(output.contains("[Courses]"), "Should contain list name in brackets")
            assertTrue(output.contains("r-001"), "Should contain reminder id")
        }

        runTest("formatReminders_single_withDueDate") {
            let reminders = [
                CKReminder(id: "r-002", title: "Appeler le médecin", list: "Perso", listId: "l2",
                           isCompleted: false, priority: 1, dueDate: "2026-04-01T10:00:00+02:00", notes: "RDV annuel", creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil)
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("Appeler le médecin"), "Should contain reminder title")
            assertTrue(output.contains("2026-04-01"), "Should contain due date")
            assertTrue(output.contains("[Perso]"), "Should contain list name")
        }

        runTest("formatReminders_completed") {
            let reminders = [
                CKReminder(id: "r-003", title: "Tâche finie", list: "Travail", listId: "l3",
                           isCompleted: true, priority: 0, dueDate: nil, notes: nil, creationDate: "2026-03-01T12:00:00+01:00", completionDate: nil)
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("✓"), "Completed reminders should show checkmark")
        }

        runTest("formatReminders_notCompleted") {
            let reminders = [
                CKReminder(id: "r-004", title: "Tâche en cours", list: "Travail", listId: "l3",
                           isCompleted: false, priority: 0, dueDate: nil, notes: nil, creationDate: "2026-03-01T12:00:00+01:00", completionDate: nil)
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("○"), "Incomplete reminders should show open circle")
        }

        runTest("formatReminders_empty") {
            let reminders: [CKReminder] = []
            let output = TextFormatter.formatReminders(reminders)
            assertEqual(output, "Aucun rappel trouvé", "Empty list should show message")
        }

        runTest("formatReminders_withPriority") {
            let reminders = [
                CKReminder(id: "r-005", title: "Urgent", list: "Travail", listId: "l3",
                           isCompleted: false, priority: 1, dueDate: nil, notes: nil, creationDate: "2026-03-01T12:00:00+01:00", completionDate: nil)
            ]
            let output = TextFormatter.formatReminders(reminders)
            assertTrue(output.contains("!1"), "High priority should show !1 indicator")
        }

        // --- JSON Formatting Tests ---

        runTest("formatReminderListsJSON") {
            let lists = [
                CKReminderList(id: "list-001", title: "Courses", source: "iCloud", color: "#FF6B6B", pendingCount: 3)
            ]
            let json = JSONFormatter.format(lists)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1)
            assertEqual(parsed[0]["id"] as? String ?? "", "list-001")
            assertEqual(parsed[0]["title"] as? String ?? "", "Courses")
            assertEqual(parsed[0]["source"] as? String ?? "", "iCloud")
            assertEqual(parsed[0]["color"] as? String ?? "", "#FF6B6B")
            assertEqual(parsed[0]["pendingCount"] as? Int ?? -1, 3)
        }

        runTest("formatRemindersJSON") {
            let reminders = [
                CKReminder(id: "r-001", title: "Acheter du pain", list: "Courses", listId: "l1",
                           isCompleted: false, priority: 0, dueDate: nil, notes: nil, creationDate: "2026-03-10T08:00:00+01:00", completionDate: nil)
            ]
            let json = JSONFormatter.format(reminders)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON array\n".utf8))
                return
            }
            assertEqual(parsed.count, 1)
            assertEqual(parsed[0]["id"] as? String ?? "", "r-001")
            assertEqual(parsed[0]["title"] as? String ?? "", "Acheter du pain")
            assertEqual(parsed[0]["list"] as? String ?? "", "Courses")
            assertEqual(parsed[0]["listId"] as? String ?? "", "l1")
            assertEqual(parsed[0]["isCompleted"] as? Bool ?? true, false)
            assertEqual(parsed[0]["priority"] as? Int ?? -1, 0)
        }

        // --- Confirmation Text Formatting Tests ---

        runTest("formatCreatedReminder") {
            let reminder = CKReminder(id: "r-new", title: "Nouvelle tâche", list: "Courses", listId: "l1",
                                      isCompleted: false, priority: 0, dueDate: nil, notes: nil, creationDate: "2026-03-17T10:00:00+01:00", completionDate: nil)
            let output = TextFormatter.formatCreatedReminder(reminder)
            assertTrue(output.hasPrefix("Rappel créé."), "Should start with confirmation")
            assertTrue(output.contains("r-new"), "Should contain ID")
            assertTrue(output.contains("Nouvelle tâche"), "Should contain title")
            assertTrue(output.contains("Courses"), "Should contain list name")
        }

        runTest("formatCompletedReminder") {
            let output = TextFormatter.formatCompletedReminder(id: "r-done", title: "Tâche finie")
            assertTrue(output.hasPrefix("Rappel complété."), "Should start with confirmation")
            assertTrue(output.contains("r-done"), "Should contain ID")
            assertTrue(output.contains("Tâche finie"), "Should contain title")
        }

        runTest("formatDeletedReminder") {
            let output = TextFormatter.formatDeletedReminder(id: "r-del", title: "Tâche supprimée")
            assertTrue(output.hasPrefix("Rappel supprimé."), "Should start with confirmation")
            assertTrue(output.contains("r-del"), "Should contain ID")
            assertTrue(output.contains("Tâche supprimée"), "Should contain title")
        }

        reportResults()
    }
}
