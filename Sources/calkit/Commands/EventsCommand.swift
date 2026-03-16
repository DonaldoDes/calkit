import Foundation

enum EventsCommand {
    /// Handle `calkit events today [--calendar <name>] [--json]`
    static func runToday(args: [String]) {
        let calendarName = extractOption("--calendar", from: args)
        let useJSON = args.contains("--json")

        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        let (start, end) = EventDateParser.todayRange()
        let events = EventKitService.shared.fetchEvents(from: start, to: end, calendarName: calendarName)

        outputEvents(events, useJSON: useJSON)
    }

    /// Handle `calkit events range <start> <end> [--calendar <name>] [--json]`
    static func runRange(args: [String]) {
        let calendarName = extractOption("--calendar", from: args)
        let useJSON = args.contains("--json")

        // Extract positional args (skip options)
        let positional = extractPositionalArgs(args)
        guard positional.count >= 2 else {
            printError("usage: calkit events range <début> <fin> [--calendar <nom>] [--json]")
            exit(1)
        }

        guard let startDate = EventDateParser.parseDate(positional[0]) else {
            printError("date de début invalide : '\(positional[0])'. Format attendu : YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SS")
            exit(1)
        }

        guard let endDate = EventDateParser.parseDate(positional[1]) else {
            printError("date de fin invalide : '\(positional[1])'. Format attendu : YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SS")
            exit(1)
        }

        // If end date is date-only (no time component), set to end of day
        let adjustedEnd: Date
        if positional[1].count <= 10 {
            // Date-only: set to 23:59:59
            let cal = Calendar.current
            adjustedEnd = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
        } else {
            adjustedEnd = endDate
        }

        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        let events = EventKitService.shared.fetchEvents(from: startDate, to: adjustedEnd, calendarName: calendarName)

        outputEvents(events, useJSON: useJSON)
    }

    /// Handle `calkit events search <term> [--calendar <name>] [--from <date>] [--to <date>] [--json]`
    static func runSearch(args: [String]) {
        let calendarName = extractOption("--calendar", from: args)
        let fromStr = extractOption("--from", from: args)
        let toStr = extractOption("--to", from: args)
        let useJSON = args.contains("--json")

        // Extract positional args (the search term)
        let positional = extractPositionalArgs(args)
        guard !positional.isEmpty else {
            printError("usage: calkit events search <terme> [--calendar <nom>] [--from <date>] [--to <date>] [--json]")
            exit(1)
        }

        let term = positional[0]

        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        // Default range: -30 days to +365 days
        let cal = Calendar.current
        let now = Date()
        let startDate: Date
        let endDate: Date

        if let fromStr = fromStr, let parsed = EventDateParser.parseDate(fromStr) {
            startDate = parsed
        } else {
            startDate = cal.date(byAdding: .day, value: -30, to: now)!
        }

        if let toStr = toStr, let parsed = EventDateParser.parseDate(toStr) {
            // If date-only, set to end of day
            if toStr.count <= 10 {
                endDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: parsed)!
            } else {
                endDate = parsed
            }
        } else {
            endDate = cal.date(byAdding: .day, value: 365, to: now)!
        }

        let results = EventKitService.shared.searchEvents(term: term, from: startDate, to: endDate, calendarName: calendarName)

        if useJSON {
            let jsonResults = results.map { result in
                CKSearchResult(
                    id: result.event.id,
                    title: result.event.title,
                    start: result.event.start,
                    end: result.event.end,
                    calendar: result.event.calendar,
                    calendarId: result.event.calendarId,
                    location: result.event.location,
                    notes: result.event.notes,
                    isAllDay: result.event.isAllDay,
                    url: result.event.url,
                    matchedOn: result.matchedOn
                )
            }
            if jsonResults.isEmpty {
                print(JSONFormatter.format(jsonResults))
            } else {
                print(JSONFormatter.format(jsonResults))
            }
        } else {
            print(TextFormatter.formatSearchResultsText(results, term: term))
        }
        exit(0)
    }

    // MARK: - Private Helpers

    private static func outputEvents(_ events: [CKEvent], useJSON: Bool) {
        if useJSON {
            print(JSONFormatter.format(events))
        } else {
            print(TextFormatter.formatEventsText(events, groupByDay: true))
        }
        exit(0)
    }

    /// Extract the value of a named option like --calendar <name>.
    private static func extractOption(_ name: String, from args: [String]) -> String? {
        guard let index = args.firstIndex(of: name), index + 1 < args.count else {
            return nil
        }
        return args[index + 1]
    }

    /// Extract positional arguments (skip flags and their values).
    private static func extractPositionalArgs(_ args: [String]) -> [String] {
        var result: [String] = []
        var i = 0
        while i < args.count {
            if args[i] == "--calendar" || args[i] == "--from" || args[i] == "--to" {
                i += 2 // skip flag + value
            } else if args[i].hasPrefix("--") {
                i += 1 // skip boolean flag
            } else {
                result.append(args[i])
                i += 1
            }
        }
        return result
    }
}
