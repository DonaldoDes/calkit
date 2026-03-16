import Foundation

enum TextFormatter {
    /// Format calendars as aligned text columns.
    /// Output: [Source]    Title          (id: xxx)
    static func formatCalendars(_ calendars: [CKCalendar]) -> String {
        if calendars.isEmpty { return "" }

        // Calculate column widths for alignment
        let maxSourceLen = calendars.map { $0.source.count }.max() ?? 0
        let maxTitleLen = calendars.map { $0.title.count }.max() ?? 0

        return calendars.map { cal in
            let paddedSource = "[\(cal.source)]".padding(
                toLength: maxSourceLen + 2, // +2 for brackets
                withPad: " ",
                startingAt: 0
            )
            let paddedTitle = cal.title.padding(
                toLength: maxTitleLen,
                withPad: " ",
                startingAt: 0
            )
            return "\(paddedSource)  \(paddedTitle)  (id: \(cal.id))"
        }.joined(separator: "\n")
    }

    /// Format events as human-readable text, optionally grouped by day.
    /// Returns "Aucun événement trouvé" if the list is empty.
    static func formatEventsText(_ events: [CKEvent], groupByDay: Bool) -> String {
        if events.isEmpty {
            return "Aucun événement trouvé"
        }

        if !groupByDay {
            return events.map { formatSingleEvent($0) }.joined(separator: "\n")
        }

        // Group events by date
        var grouped: [(String, [CKEvent])] = []
        var currentDate = ""
        var currentGroup: [CKEvent] = []

        for event in events {
            let date = EventDateParser.extractDate(event.start)
            if date != currentDate {
                if !currentGroup.isEmpty {
                    grouped.append((currentDate, currentGroup))
                }
                currentDate = date
                currentGroup = [event]
            } else {
                currentGroup.append(event)
            }
        }
        if !currentGroup.isEmpty {
            grouped.append((currentDate, currentGroup))
        }

        return grouped.map { (date, dayEvents) in
            let dayName = EventDateParser.dayName(for: date)
            let header = "\(date) (\(dayName))"
            let lines = dayEvents.map { "  \(formatSingleEvent($0))" }
            return ([header] + lines).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    /// Format search results as human-readable text with match indicators.
    /// Returns "Aucun résultat pour '<term>'" if the list is empty.
    static func formatSearchResultsText(_ results: [(event: CKEvent, matchedOn: String)], term: String) -> String {
        if results.isEmpty {
            return "Aucun résultat pour '\(term)'"
        }

        // Group results by date
        var grouped: [(String, [(event: CKEvent, matchedOn: String)])] = []
        var currentDate = ""
        var currentGroup: [(event: CKEvent, matchedOn: String)] = []

        for result in results {
            let date = EventDateParser.extractDate(result.event.start)
            if date != currentDate {
                if !currentGroup.isEmpty {
                    grouped.append((currentDate, currentGroup))
                }
                currentDate = date
                currentGroup = [result]
            } else {
                currentGroup.append(result)
            }
        }
        if !currentGroup.isEmpty {
            grouped.append((currentDate, currentGroup))
        }

        return grouped.map { (date, dayResults) in
            let dayName = EventDateParser.dayName(for: date)
            let header = "\(date) (\(dayName))"
            let lines = dayResults.map { result in
                "  \(formatSingleEvent(result.event))  [match: \(result.matchedOn)]"
            }
            return ([header] + lines).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    /// Format a single event line: "HH:MM–HH:MM  Title  [Calendar]"
    /// or "(Toute la journée) Title  [Calendar]" for all-day events.
    private static func formatSingleEvent(_ event: CKEvent) -> String {
        let timeCol: String
        if event.isAllDay {
            timeCol = "(Toute la journée)"
        } else {
            let startTime = EventDateParser.extractTime(event.start)
            let endTime = EventDateParser.extractTime(event.end)
            timeCol = "\(startTime)–\(endTime)"
        }
        return "\(timeCol)  \(event.title)  [\(event.calendar)]"
    }
}
