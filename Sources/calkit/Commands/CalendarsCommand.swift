import Foundation

enum CalendarsCommand {
    /// Handle `calkit calendars list [--json]`
    static func runList(args: [String]) {
        let useJSON = args.contains("--json")

        // Request access synchronously
        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        let calendars = EventKitService.shared.fetchCalendars()

        if useJSON {
            print(JSONFormatter.format(calendars))
        } else {
            let output = TextFormatter.formatCalendars(calendars)
            if !output.isEmpty {
                print(output)
            }
        }
        exit(0)
    }
}
