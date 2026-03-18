import EventKit
import Foundation

enum RemindersWriteCommand {

    // MARK: - US-010: Create

    /// Handle `calkit reminders create <titre> [--list <nom>] [--due <datetime>] [--priority <1-9>] [--notes <texte>]`
    static func runCreate(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit reminders create — Creer un nouveau rappel

                Usage: calkit reminders create <titre> [--list <nom>] [--due <datetime>] [--priority <1-9>] [--notes <texte>] [--alarm <datetime>] [--recurrence <rule>] [--json]

                Arguments:
                  <titre>       Titre du rappel (obligatoire)

                Options:
                  --list        Nom de la liste cible (defaut : liste par defaut)
                  --due         Date d'echeance (format YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DD)
                  --priority    Priorite de 0 a 9 (1=haute, 9=basse, 0=aucune, defaut 0)
                  --notes       Notes associees
                  --alarm       Date/heure de declenchement de l'alerte (format YYYY-MM-DDTHH:MM:SS)
                  --recurrence  Regle de recurrence (FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO,WE,FR, FREQ=MONTHLY, FREQ=YEARLY)
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit reminders create "Appeler le medecin"
                  calkit reminders create "Faire les courses" --list "Courses" --due 2026-03-25T10:00:00
                  calkit reminders create "Preparer la demo" --list "Travail" --due 2026-03-25T09:00:00 --priority 1 --notes "Inclure les slides"
                  calkit reminders create "Reunion hebdo" --due 2026-03-25T09:00:00 --alarm 2026-03-25T08:30:00 --recurrence FREQ=WEEKLY
                  calkit reminders create "Standup" --due 2026-03-20T09:00:00 --recurrence FREQ=DAILY --alarm 2026-03-20T08:55:00
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = CreateReminderArgs.parse(args)
        let parsed: CreateReminderArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request reminder access
        let granted = EventKitService.shared.requestReminderAccessSync()
        guard granted else {
            printError("acces aux rappels refuse. Autorisez calkit dans Reglages Systeme > Confidentialite > Rappels.")
            exit(2)
        }

        // Create reminder
        do {
            let reminder = try EventKitService.shared.createReminder(
                title: parsed.title,
                listName: parsed.listName,
                dueDate: parsed.dueDate,
                priority: parsed.priority,
                notes: parsed.notes,
                alarm: parsed.alarm,
                recurrence: parsed.recurrence
            )

            if parsed.useJSON {
                print(JSONFormatter.format(reminder))
            } else {
                print(TextFormatter.formatCreatedReminder(reminder))
            }
            exit(0)
        } catch let error as ReminderError {
            switch error {
            case .listNotFound(let name):
                printError("liste '\(name)' introuvable.")
                exit(3)
            case .listAmbiguous(let name):
                printError("liste '\(name)' ambigue — plusieurs listes correspondent.")
                exit(1)
            case .notFound(let id):
                printError("rappel '\(id)' introuvable.")
                exit(3)
            }
        } catch {
            printError("echec de la creation : \(error.localizedDescription)")
            exit(4)
        }
    }

    // MARK: - US-011: Complete

    /// Handle `calkit reminders complete <id> [--json]`
    static func runComplete(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit reminders complete — Marquer un rappel comme complete

                Usage: calkit reminders complete <id> [--json]

                Arguments:
                  <id>          Identifiant du rappel (obligatoire)

                Options:
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit reminders complete abc-123
                  calkit reminders complete abc-123 --json
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = CompleteReminderArgs.parse(args)
        let parsed: CompleteReminderArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request reminder access
        let granted = EventKitService.shared.requestReminderAccessSync()
        guard granted else {
            printError("acces aux rappels refuse. Autorisez calkit dans Reglages Systeme > Confidentialite > Rappels.")
            exit(2)
        }

        // Complete reminder
        do {
            let (title, alreadyCompleted) = try EventKitService.shared.completeReminder(id: parsed.id)

            if parsed.useJSON {
                let result = CKReminderActionResult(id: parsed.id, title: title, action: "completed")
                print(JSONFormatter.format(result))
            } else {
                if alreadyCompleted {
                    print(TextFormatter.formatCompletedReminder(id: parsed.id, title: title))
                    print("  (deja complete)")
                } else {
                    print(TextFormatter.formatCompletedReminder(id: parsed.id, title: title))
                }
            }
            exit(0)
        } catch let error as ReminderError {
            switch error {
            case .notFound(let id):
                printError("rappel '\(id)' introuvable.")
                exit(3)
            default:
                printError("erreur inattendue.")
                exit(4)
            }
        } catch {
            printError("echec de la completion : \(error.localizedDescription)")
            exit(4)
        }
    }

    // MARK: - US-012: Delete

    /// Handle `calkit reminders delete <id> [--json]`
    static func runDelete(args: [String]) {
        // Help flag
        if args.isEmpty || args.contains("--help") || args.contains("-h") {
            print("""
                calkit reminders delete — Supprimer un rappel

                Usage: calkit reminders delete <id> [--json]

                Arguments:
                  <id>          Identifiant du rappel (obligatoire)

                Options:
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exit codes:
                  0   Suppression reussie
                  3   Rappel introuvable
                  4   Erreur EventKit lors de la suppression

                Exemples:
                  calkit reminders delete abc-123
                  calkit reminders delete abc-123 --json
                """)
            if args.isEmpty {
                exit(1)
            }
            exit(0)
        }

        // Parse arguments
        let parseResult = DeleteReminderArgs.parse(args)
        let parsed: DeleteReminderArgs
        switch parseResult {
        case .success(let p):
            parsed = p
        case .failure(let err):
            printError(err.message)
            exit(1)
        }

        // Request reminder access
        let granted = EventKitService.shared.requestReminderAccessSync()
        guard granted else {
            printError("acces aux rappels refuse. Autorisez calkit dans Reglages Systeme > Confidentialite > Rappels.")
            exit(2)
        }

        // Delete reminder
        do {
            let title = try EventKitService.shared.deleteReminder(id: parsed.id)

            if parsed.useJSON {
                let result = CKReminderActionResult(id: parsed.id, title: title, action: "deleted")
                print(JSONFormatter.format(result))
            } else {
                print(TextFormatter.formatDeletedReminder(id: parsed.id, title: title))
            }
            exit(0)
        } catch let error as ReminderError {
            switch error {
            case .notFound(let id):
                printError("rappel '\(id)' introuvable.")
                exit(3)
            default:
                printError("erreur inattendue.")
                exit(4)
            }
        } catch {
            printError("echec de la suppression : \(error.localizedDescription)")
            exit(4)
        }
    }
}
