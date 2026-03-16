import Foundation

enum Help {
    static let global = """
        calkit — CLI macOS pour gérer calendriers et rappels (tous fournisseurs, zéro config)

        Usage: calkit <domaine> <commande> [options]

        Domaines:
          calendars   Lister les calendriers disponibles et leur fournisseur
          events      Consulter, rechercher, créer, modifier et supprimer des événements
          reminders   Gérer les rappels (listes, consultation, CRUD)

        Options globales:
          --help, -h  Afficher l'aide

        Exemples:
          calkit calendars list
          calkit events today
          calkit events create "Réunion" --start 2026-03-20T14:00:00 --end 2026-03-20T15:00:00
          calkit --help

        Lancez 'calkit <domaine> --help' pour l'aide détaillée d'un domaine.
        """

    static let calendars = """
        calkit calendars — Gestion des calendriers

        Commandes:
          list    Lister tous les calendriers disponibles avec leur fournisseur source

        Exemple:
          calkit calendars list
          calkit calendars list --json
        """

    static let events = """
        calkit events — Gestion des événements calendrier

        Commandes:
          today    Consulter les événements du jour
          range    Consulter les événements sur une plage de dates
          search   Rechercher des événements par terme
          create   Créer un nouvel événement
          update   Modifier un événement existant
          delete   Supprimer un événement

        Exemple:
          calkit events today
          calkit events today --json
          calkit events range 2026-03-20 2026-03-27
          calkit events search "réunion"
          calkit events create "Standup" --start 2026-03-20T09:00:00 --end 2026-03-20T09:30:00
        """

    static let reminders = """
        calkit reminders — Gestion des rappels

        Commandes:
          lists     Lister toutes les listes de rappels
          list      Consulter les rappels d'une liste
          create    Créer un rappel
          complete  Marquer un rappel comme complété
          delete    Supprimer un rappel

        Exemple:
          calkit reminders lists
          calkit reminders list --list "Courses"
          calkit reminders create "Appeler le médecin" --due 2026-03-20T10:00:00
        """

    static func forDomain(_ domain: String) -> String? {
        switch domain {
        case "calendars":
            return calendars
        case "events":
            return events
        case "reminders":
            return reminders
        default:
            return nil
        }
    }

    static let validDomains = ["calendars", "events", "reminders"]
}
