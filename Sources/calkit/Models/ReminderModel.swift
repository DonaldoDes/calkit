import Foundation

struct CKReminderList: Encodable {
    let id: String          // calendarIdentifier
    let title: String
    let source: String      // source.title
    let color: String       // hex string or "default"
    let pendingCount: Int   // incomplete reminders count
}

struct CKReminder: Encodable {
    let id: String          // calendarItemIdentifier
    let title: String
    let list: String        // list title
    let listId: String      // calendarIdentifier
    let isCompleted: Bool
    let priority: Int       // 0-9
    let dueDate: String?    // ISO 8601 or nil
    let notes: String?
    let creationDate: String? // ISO 8601
}

/// Result of a reminder action (complete, delete) for JSON output.
struct CKReminderActionResult: Encodable {
    let id: String
    let title: String
    let action: String      // "completed" or "deleted"
}
