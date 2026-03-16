import EventKit
import Foundation

/// Parses simplified RRULE strings into EKRecurrenceRule.
/// Supported formats:
///   FREQ=DAILY
///   FREQ=WEEKLY
///   FREQ=WEEKLY;BYDAY=MO,WE,FR
///   FREQ=MONTHLY
enum RecurrenceParser {
    /// Day abbreviation mapping to EKWeekday.
    private static let dayMap: [String: EKWeekday] = [
        "MO": .monday,
        "TU": .tuesday,
        "WE": .wednesday,
        "TH": .thursday,
        "FR": .friday,
        "SA": .saturday,
        "SU": .sunday
    ]

    /// Parse an RRULE string into an EKRecurrenceRule.
    /// Returns nil if the string is not a recognized format.
    static func parse(_ rrule: String) -> EKRecurrenceRule? {
        // Split by semicolon into key=value pairs
        var parts: [String: String] = [:]
        for component in rrule.split(separator: ";") {
            let kv = component.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            parts[String(kv[0])] = String(kv[1])
        }

        guard let freqStr = parts["FREQ"] else { return nil }

        let frequency: EKRecurrenceFrequency
        switch freqStr {
        case "DAILY":
            frequency = .daily
        case "WEEKLY":
            frequency = .weekly
        case "MONTHLY":
            frequency = .monthly
        case "YEARLY":
            frequency = .yearly
        default:
            return nil
        }

        // Parse BYDAY if present
        var daysOfWeek: [EKRecurrenceDayOfWeek]? = nil
        if let byDay = parts["BYDAY"] {
            let dayAbbrevs = byDay.split(separator: ",").map(String.init)
            var days: [EKRecurrenceDayOfWeek] = []
            for abbrev in dayAbbrevs {
                guard let weekday = dayMap[abbrev] else { return nil }
                days.append(EKRecurrenceDayOfWeek(weekday))
            }
            if !days.isEmpty {
                daysOfWeek = days
            }
        }

        let interval = 1

        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: interval,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
    }
}
