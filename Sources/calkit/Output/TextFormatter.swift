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
}
