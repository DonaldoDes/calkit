import EventKit
import Foundation

enum RemindersReadCommand {

    // MARK: - US-008: Lists

    /// Handle `calkit reminders lists [--json]`
    static func runLists(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit reminders lists — Lister toutes les listes de rappels

                Usage: calkit reminders lists [--json]

                Options:
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit reminders lists
                  calkit reminders lists --json
                """)
            exit(0)
        }

        let useJSON = args.contains("--json")

        let granted = EventKitService.shared.requestReminderAccessSync()
        guard granted else {
            printError("acces aux rappels refuse. Autorisez calkit dans Reglages Systeme > Confidentialite > Rappels.")
            exit(2)
        }

        let lists = EventKitService.shared.fetchReminderLists()

        if useJSON {
            print(JSONFormatter.format(lists))
        } else {
            let output = TextFormatter.formatReminderLists(lists)
            if !output.isEmpty {
                print(output)
            }
        }
        exit(0)
    }

    // MARK: - US-009: List

    /// Handle `calkit reminders list [--list <nom>] [--completed] [--due-before <date>] [--json]`
    static func runList(args: [String]) {
        // Help flag
        if args.contains("--help") || args.contains("-h") {
            print("""
                calkit reminders list — Consulter les rappels

                Usage: calkit reminders list [--list <nom>] [--completed] [--due-before <date>] [--json]

                Options:
                  --list        Filtrer par nom de liste de rappels
                  --completed   Inclure les rappels completes (defaut : non completes uniquement)
                  --due-before  Filtrer les rappels dont l'echeance est avant cette date (format YYYY-MM-DD)
                  --json        Sortie au format JSON
                  --help, -h    Afficher cette aide

                Exemples:
                  calkit reminders list
                  calkit reminders list --list "Courses"
                  calkit reminders list --completed --json
                  calkit reminders list --due-before 2026-04-01
                  calkit reminders list --list "Travail" --due-before 2026-04-01 --json
                """)
            exit(0)
        }

        let parsed = ListReminderArgs.parse(args)

        let granted = EventKitService.shared.requestReminderAccessSync()
        guard granted else {
            printError("acces aux rappels refuse. Autorisez calkit dans Reglages Systeme > Confidentialite > Rappels.")
            exit(2)
        }

        do {
            let reminders = try EventKitService.shared.fetchReminders(
                listName: parsed.listName,
                includeCompleted: parsed.includeCompleted,
                dueBefore: parsed.dueBefore
            )

            if parsed.useJSON {
                print(JSONFormatter.format(reminders))
            } else {
                print(TextFormatter.formatReminders(reminders))
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
            printError("echec de la lecture : \(error.localizedDescription)")
            exit(4)
        }
    }
}
