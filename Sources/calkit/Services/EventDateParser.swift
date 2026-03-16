import Foundation

enum EventDateParser {
    /// Parse a date string in YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS format.
    static func parseDate(_ string: String) -> Date? {
        // Try datetime first (more specific)
        let dtFormatter = DateFormatter()
        dtFormatter.locale = Locale(identifier: "en_US_POSIX")

        // YYYY-MM-DDTHH:MM:SS
        dtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dtFormatter.date(from: string) {
            return date
        }

        // YYYY-MM-DDTHH:MM
        dtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = dtFormatter.date(from: string) {
            return date
        }

        // YYYY-MM-DD (date only → midnight)
        dtFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dtFormatter.date(from: string) {
            return date
        }

        return nil
    }

    /// Returns the date range for today: 00:00:00 to 23:59:59.
    static func todayRange() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let startOfDay = cal.startOfDay(for: now)
        var endComponents = DateComponents()
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
        return (startOfDay, endOfDay)
    }

    /// Format a Date to ISO 8601 with local timezone offset.
    static func formatISO8601(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.string(from: date)
    }

    /// Extract time string "HH:MM" from an ISO 8601 date string.
    static func extractTime(_ isoString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Try with timezone offset
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        if let date = formatter.date(from: isoString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }

        // Try without timezone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: isoString) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }

        // Fallback: extract from string directly
        if let tIndex = isoString.firstIndex(of: "T") {
            let timeStart = isoString.index(after: tIndex)
            let timeStr = String(isoString[timeStart...])
            if timeStr.count >= 5 {
                return String(timeStr.prefix(5))
            }
        }
        return "??:??"
    }

    /// Extract date string "YYYY-MM-DD" from an ISO 8601 date string.
    static func extractDate(_ isoString: String) -> String {
        if isoString.count >= 10 {
            return String(isoString.prefix(10))
        }
        return isoString
    }

    /// Get localized day name for a date string "YYYY-MM-DD".
    static func dayName(for dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "fr_FR")
        dayFormatter.dateFormat = "EEEE"
        let name = dayFormatter.string(from: date)
        // Capitalize first letter
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
