import Foundation

struct CKCalendar: Codable {
    let id: String
    let title: String
    let source: String      // "account (type)" e.g. "donaldo@gmail.com (Google)", or "iCloud" if title=type
    let color: String       // Hex "#RRGGBB"

    /// Sort calendars alphabetically by title (case-insensitive, locale-aware).
    static func sortedAlphabetically(_ calendars: [CKCalendar]) -> [CKCalendar] {
        calendars.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
