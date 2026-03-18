import Foundation

/// Parsed arguments for the `reminders create` command.
struct CreateReminderArgs {
    let title: String
    let listName: String?
    let dueDate: String?
    let priority: Int       // 0-9, default 0
    let notes: String?
    let alarm: String?      // ISO 8601 datetime for alarm trigger
    let recurrence: String? // RRULE string (e.g. FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO,WE)
    let url: String?        // associated URL
    let useJSON: Bool

    /// Parse raw CLI arguments into CreateReminderArgs.
    /// Returns .failure with an error message if required args are missing or invalid.
    static func parse(_ args: [String]) -> Result<CreateReminderArgs, ParseError> {
        var positional: [String] = []
        var options: [String: String] = [:]
        var flags: Set<String> = []
        let valuedOptions: Set<String> = ["--list", "--due", "--priority", "--notes", "--alarm", "--recurrence", "--url"]

        var i = 0
        while i < args.count {
            let arg = args[i]
            if valuedOptions.contains(arg) {
                guard i + 1 < args.count else {
                    return .failure(ParseError(message: "option '\(arg)' nécessite une valeur."))
                }
                options[arg] = args[i + 1]
                i += 2
            } else if arg.hasPrefix("--") {
                flags.insert(arg)
                i += 1
            } else {
                positional.append(arg)
                i += 1
            }
        }

        // Title is the first positional argument
        guard let title = positional.first, !title.isEmpty else {
            return .failure(ParseError(message: "titre manquant. Usage : calkit reminders create <titre> [--list <nom>] [--due <datetime>] [--priority <1-9>] [--notes <texte>]"))
        }

        // Priority validation
        var priority = 0
        if let priorityStr = options["--priority"] {
            guard let p = Int(priorityStr) else {
                return .failure(ParseError(message: "priorité invalide : '\(priorityStr)'. Valeur numérique attendue (0-9)."))
            }
            guard p >= 0 && p <= 9 else {
                return .failure(ParseError(message: "priorité invalide : \(p). Valeurs autorisées : 0-9 (1=haute, 9=basse, 0=aucune)."))
            }
            priority = p
        }

        // Due date validation (if provided)
        if let dueDateStr = options["--due"] {
            guard EventDateParser.parseDate(dueDateStr) != nil else {
                return .failure(ParseError(message: "date d'échéance invalide : '\(dueDateStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DD"))
            }
        }

        // Alarm date validation (if provided)
        if let alarmStr = options["--alarm"] {
            guard EventDateParser.parseDate(alarmStr) != nil else {
                return .failure(ParseError(message: "date d'alarme invalide : '\(alarmStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DD"))
            }
        }

        // Recurrence rule validation (if provided)
        if let rruleStr = options["--recurrence"] {
            guard RecurrenceParser.parse(rruleStr) != nil else {
                return .failure(ParseError(message: "règle de récurrence invalide : '\(rruleStr)'. Formats supportés : FREQ=DAILY, FREQ=WEEKLY, FREQ=WEEKLY;BYDAY=MO,WE,FR, FREQ=MONTHLY, FREQ=YEARLY"))
            }
        }

        // URL validation (if provided)
        if let urlStr = options["--url"] {
            guard URL(string: urlStr) != nil, urlStr.contains(":") else {
                return .failure(ParseError(message: "URL invalide : '\(urlStr)'. Format attendu : https://example.com"))
            }
        }

        return .success(CreateReminderArgs(
            title: title,
            listName: options["--list"],
            dueDate: options["--due"],
            priority: priority,
            notes: options["--notes"],
            alarm: options["--alarm"],
            recurrence: options["--recurrence"],
            url: options["--url"],
            useJSON: flags.contains("--json")
        ))
    }
}
