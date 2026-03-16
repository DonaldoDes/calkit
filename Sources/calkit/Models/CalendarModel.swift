import Foundation

struct CKCalendar: Codable {
    let id: String
    let title: String
    let source: String      // "iCloud", "Google", "Exchange", "Local", "CalDAV"
    let color: String       // Hex "#RRGGBB"
}
