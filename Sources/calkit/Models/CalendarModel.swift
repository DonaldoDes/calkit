import Foundation

struct CKCalendar: Codable {
    let id: String
    let title: String
    let source: String      // "account (type)" e.g. "donaldo@gmail.com (Google)", or "iCloud" if title=type
    let color: String       // Hex "#RRGGBB"
}
