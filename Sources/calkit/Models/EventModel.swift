import Foundation

struct CKEvent: Codable {
    let id: String
    let title: String
    let start: String       // ISO 8601 with timezone
    let end: String
    let calendar: String    // Calendar display name
    let calendarId: String
    let location: String
    let notes: String
    let isAllDay: Bool
    let url: String
}

struct CKSearchResult: Codable {
    let id: String
    let title: String
    let start: String
    let end: String
    let calendar: String
    let calendarId: String
    let location: String
    let notes: String
    let isAllDay: Bool
    let url: String
    let matchedOn: String
}

struct CKDeleteResult: Codable {
    let id: String
    let title: String
    let span: String
    let deleted: Bool
}
