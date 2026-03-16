import EventKit
import Foundation

enum EventsReadCommand {
    /// Handle `calkit events today [--calendar <name>] [--json]`
    static func runToday(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit events today — Consulter les événements du jour

                Usage: calkit events today [--calendar <nom>] [--json]

                Options:
                  --calendar    Filtrer par nom de calendrier
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit events today
                  calkit events today --json
                  calkit events today --calendar Travail
                """)
            exit(0)
        }

        let calendarName = EventsHelpers.extractOption("--calendar", from: args)
        let useJSON = args.contains("--json")

        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        let (start, end) = EventDateParser.todayRange()
        let events = EventKitService.shared.fetchEvents(from: start, to: end, calendarName: calendarName)

        EventsHelpers.outputEvents(events, useJSON: useJSON)
    }

    /// Handle `calkit events range <start> <end> [--calendar <name>] [--json]`
    static func runRange(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit events range — Consulter les événements sur une plage de dates

                Usage: calkit events range <début> <fin> [--calendar <nom>] [--json]

                Arguments:
                  <début>       Date de début (format YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SS)
                  <fin>         Date de fin (format YYYY-MM-DD ou YYYY-MM-DDTHH:MM:SS)

                Options:
                  --calendar    Filtrer par nom de calendrier
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit events range 2026-03-20 2026-03-27
                  calkit events range 2026-03-20 2026-03-27 --json
                  calkit events range 2026-03-20 2026-03-27 --calendar Travail
                """)
            exit(0)
        }

        let calendarName = EventsHelpers.extractOption("--calendar", from: args)
        let useJSON = args.contains("--json")

        // Extract positional args (skip options)
        let positional = EventsHelpers.extractPositionalArgs(args)
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
            let cal = Calendar.current
            guard let eod = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) else {
                printError("impossible de calculer la fin de journée pour '\(positional[1])'.")
                exit(1)
            }
            adjustedEnd = eod
        } else {
            adjustedEnd = endDate
        }

        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        let events = EventKitService.shared.fetchEvents(from: startDate, to: adjustedEnd, calendarName: calendarName)

        EventsHelpers.outputEvents(events, useJSON: useJSON)
    }

    /// Handle `calkit events search <term> [--calendar <name>] [--from <date>] [--to <date>] [--json]`
    static func runSearch(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit events search — Rechercher des événements par terme

                Usage: calkit events search <terme> [--calendar <nom>] [--from <date>] [--to <date>] [--json]

                Arguments:
                  <terme>       Terme de recherche (obligatoire)

                Options:
                  --calendar    Filtrer par nom de calendrier
                  --from        Date de début de la plage de recherche (défaut : -30 jours)
                  --to          Date de fin de la plage de recherche (défaut : +365 jours)
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit events search "réunion"
                  calkit events search "standup" --from 2026-03-01 --to 2026-03-31
                  calkit events search "sprint" --calendar Travail --json
                """)
            exit(0)
        }

        let calendarName = EventsHelpers.extractOption("--calendar", from: args)
        let fromStr = EventsHelpers.extractOption("--from", from: args)
        let toStr = EventsHelpers.extractOption("--to", from: args)
        let useJSON = args.contains("--json")

        // Extract positional args (the search term)
        let positional = EventsHelpers.extractPositionalArgs(args)
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
            guard let defaultStart = cal.date(byAdding: .day, value: -30, to: now) else {
                printError("impossible de calculer la date de début par défaut.")
                exit(1)
            }
            startDate = defaultStart
        }

        if let toStr = toStr, let parsed = EventDateParser.parseDate(toStr) {
            // If date-only, set to end of day
            if toStr.count <= 10 {
                guard let eod = cal.date(bySettingHour: 23, minute: 59, second: 59, of: parsed) else {
                    printError("impossible de calculer la fin de journée pour '\(toStr)'.")
                    exit(1)
                }
                endDate = eod
            } else {
                endDate = parsed
            }
        } else {
            guard let defaultEnd = cal.date(byAdding: .day, value: 365, to: now) else {
                printError("impossible de calculer la date de fin par défaut.")
                exit(1)
            }
            endDate = defaultEnd
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
            print(JSONFormatter.format(jsonResults))
        } else {
            print(TextFormatter.formatSearchResultsText(results, term: term))
        }
        exit(0)
    }
}
