import EventKit
import Foundation

enum EventsWriteCommand {
    /// Handle `calkit events create <title> --start <datetime> --end <datetime> [options]`
    static func runCreate(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit events create — Créer un nouvel événement

                Usage: calkit events create <titre> --start <datetime> --end <datetime> [options]

                Arguments:
                  <titre>       Titre de l'événement (obligatoire)

                Options:
                  --start       Date/heure de début (obligatoire, format YYYY-MM-DDTHH:MM:SS)
                  --end         Date/heure de fin (obligatoire, format YYYY-MM-DDTHH:MM:SS)
                  --calendar-id UUID du calendrier (prioritaire sur --calendar)
                  --calendar    Nom du calendrier cible (défaut : calendrier par défaut)
                  --location    Lieu de l'événement
                  --notes       Notes associées
                  --recurrence  Règle de récurrence (FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO,WE,FR, etc.)
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit events create "Réunion équipe" --start 2026-03-20T14:00:00 --end 2026-03-20T15:00:00
                  calkit events create "Standup" --start 2026-03-20T09:00:00 --end 2026-03-20T09:30:00 --calendar Travail --recurrence FREQ=DAILY
                  calkit events create "Sprint review" --start 2026-03-20T16:00:00 --end 2026-03-20T17:00:00 --json
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = CreateEventArgs.parse(args)
        let parsed: CreateEventArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request calendar access
        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        // Parse dates (already validated by CreateEventArgs.parse)
        guard let startDate = EventDateParser.parseDate(parsed.startStr) else {
            printError("date de début invalide : '\(parsed.startStr)'.")
            exit(1)
        }
        guard let endDate = EventDateParser.parseDate(parsed.endStr) else {
            printError("date de fin invalide : '\(parsed.endStr)'.")
            exit(1)
        }

        // Create event
        do {
            let event = try EventKitService.shared.createEvent(
                title: parsed.title,
                start: startDate,
                end: endDate,
                calendarId: parsed.calendarId,
                calendarName: parsed.calendarName,
                location: parsed.location,
                notes: parsed.notes,
                recurrenceRule: parsed.recurrence
            )

            if parsed.useJSON {
                print(JSONFormatter.format(event))
            } else {
                print(TextFormatter.formatCreatedEvent(event))
            }
            exit(0)
        } catch let error as CreateEventError {
            switch error {
            case .calendarNotFound(let name):
                printError("calendrier '\(name)' introuvable.")
                exit(4)
            case .ambiguousCalendar(let name):
                printError("calendrier '\(name)' ambigu — plusieurs calendriers correspondent.")
                exit(4)
            case .calendarIdNotFound(let id):
                printError("calendrier avec l'id '\(id)' introuvable.")
                exit(4)
            }
        } catch {
            printError("échec de la création : \(error.localizedDescription)")
            exit(4)
        }
    }

    // MARK: - Update

    /// Handle `calkit events update <id> [--title <titre>] [--start <datetime>] [--end <datetime>] [--location <lieu>] [--notes <texte>] [--json]`
    static func runUpdate(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit events update — Modifier un événement existant

                Usage: calkit events update <id> [--title <titre>] [--start <datetime>] [--end <datetime>] [--location <lieu>] [--notes <texte>] [--json]

                Arguments:
                  <id>          Identifiant de l'événement (obligatoire)

                Options:
                  --title       Nouveau titre
                  --start       Nouvelle date/heure de début (format YYYY-MM-DDTHH:MM:SS)
                  --end         Nouvelle date/heure de fin (format YYYY-MM-DDTHH:MM:SS)
                  --location    Nouveau lieu
                  --notes       Nouvelles notes
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Au moins une option de modification est requise.

                Exemples:
                  calkit events update abc123 --title "Réunion modifiée"
                  calkit events update abc123 --start 2026-03-20T15:00:00 --end 2026-03-20T16:00:00
                  calkit events update abc123 --title "Standup" --location "Salle B" --json
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = UpdateEventArgs.parse(args)
        let parsed: UpdateEventArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request calendar access
        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        // Parse dates if provided
        var startDate: Date? = nil
        var endDate: Date? = nil
        if let startStr = parsed.startStr {
            startDate = EventDateParser.parseDate(startStr)
        }
        if let endStr = parsed.endStr {
            endDate = EventDateParser.parseDate(endStr)
        }

        // Update event
        do {
            let event = try EventKitService.shared.updateEvent(
                id: parsed.id,
                title: parsed.title,
                start: startDate,
                end: endDate,
                location: parsed.location,
                notes: parsed.notes
            )

            if parsed.useJSON {
                print(JSONFormatter.format(event))
            } else {
                print(TextFormatter.formatUpdatedEvent(event))
            }
            exit(0)
        } catch let error as UpdateEventError {
            switch error {
            case .notFound(let id):
                printError("événement '\(id)' introuvable.")
                exit(3)
            }
        } catch {
            printError("échec de la mise à jour : \(error.localizedDescription)")
            exit(4)
        }
    }

    // MARK: - Delete

    /// Handle `calkit events delete <id> [--span thisEvent|futureEvents] [--json]`
    static func runDelete(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit events delete — Supprimer un événement

                Usage: calkit events delete <id> [--span thisEvent|futureEvents] [--json]

                Arguments:
                  <id>          Identifiant de l'événement (obligatoire)

                Options:
                  --span        Portée de la suppression : thisEvent (défaut) ou futureEvents
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit events delete abc123
                  calkit events delete abc123 --span futureEvents
                  calkit events delete abc123 --json
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = DeleteEventArgs.parse(args)
        let parsed: DeleteEventArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request calendar access
        let granted = EventKitService.shared.requestAccessSync()
        guard granted else {
            printError("accès au calendrier refusé. Autorisez calkit dans Réglages Système > Confidentialité > Calendriers.")
            exit(2)
        }

        // Map span string to EKSpan
        let ekSpan: EKSpan = parsed.span == "futureEvents" ? .futureEvents : .thisEvent

        // Delete event
        do {
            let result = try EventKitService.shared.deleteEvent(id: parsed.id, span: ekSpan)
            if parsed.useJSON {
                print(JSONFormatter.formatDeletedEvent(id: parsed.id, title: result.title, span: result.span))
            } else {
                print(TextFormatter.formatDeletedEvent(id: parsed.id, title: result.title, span: result.span))
            }
            exit(0)
        } catch let error as DeleteEventError {
            switch error {
            case .notFound(let id):
                printError("événement '\(id)' introuvable.")
                exit(3)
            }
        } catch {
            printError("échec de la suppression : \(error.localizedDescription)")
            exit(4)
        }
    }
}
