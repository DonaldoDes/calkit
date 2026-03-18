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

    /// Reverse mapping from EKWeekday to day abbreviation.
    private static let reverseDayMap: [EKWeekday: String] = [
        .monday: "MO",
        .tuesday: "TU",
        .wednesday: "WE",
        .thursday: "TH",
        .friday: "FR",
        .saturday: "SA",
        .sunday: "SU"
    ]

    /// Format an EKRecurrenceRule into a simplified RRULE string.
    static func format(_ rule: EKRecurrenceRule) -> String {
        let freqStr: String
        switch rule.frequency {
        case .daily:   freqStr = "DAILY"
        case .weekly:  freqStr = "WEEKLY"
        case .monthly: freqStr = "MONTHLY"
        case .yearly:  freqStr = "YEARLY"
        @unknown default: freqStr = "DAILY"
        }

        var result = "FREQ=\(freqStr)"

        if let days = rule.daysOfTheWeek, !days.isEmpty {
            let dayStrs = days.compactMap { reverseDayMap[$0.dayOfTheWeek] }
            if !dayStrs.isEmpty {
                result += ";BYDAY=\(dayStrs.joined(separator: ","))"
            }
        }

        return result
    }

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
