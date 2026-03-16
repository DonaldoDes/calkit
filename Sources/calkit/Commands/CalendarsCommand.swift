import Foundation

enum CalendarsCommand {
    /// Handle `calkit calendars list [--json]`
    static func runList(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit calendars list — Lister tous les calendriers disponibles

                Usage: calkit calendars list [--json]

                Options:
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit calendars list
                  calkit calendars list --json
                """)
            exit(0)
        }

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
