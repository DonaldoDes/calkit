import Foundation

/// Parse error for CreateEventArgs.
struct ParseError: Error {
    let message: String
}

/// Parsed arguments for the `events create` command.
struct CreateEventArgs {
    let title: String
    let startStr: String
    let endStr: String
    let calendarId: String?
    let calendarName: String?
    let location: String?
    let notes: String?
    let recurrence: String?
    let useJSON: Bool

    /// Parse raw CLI arguments into CreateEventArgs.
    /// Returns .failure with an error message if required args are missing or invalid.
    static func parse(_ args: [String]) -> Result<CreateEventArgs, ParseError> {
        // Extract positional args (skip flags and their values)
        var positional: [String] = []
        var options: [String: String] = [:]
        var flags: Set<String> = []
        let valuedOptions: Set<String> = ["--start", "--end", "--calendar", "--calendar-id", "--location", "--notes", "--recurrence"]

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
            return .failure(ParseError(message: "titre manquant. Usage : calkit events create <titre> --start <datetime> --end <datetime>"))
        }

        // --start is required
        guard let startStr = options["--start"] else {
            return .failure(ParseError(message: "--start est obligatoire. Usage : calkit events create <titre> --start <datetime> --end <datetime>"))
        }

        // --end is required
        guard let endStr = options["--end"] else {
            return .failure(ParseError(message: "--end est obligatoire. Usage : calkit events create <titre> --start <datetime> --end <datetime>"))
        }

        // Validate date formats
        guard EventDateParser.parseDate(startStr) != nil else {
            return .failure(ParseError(message: "date de début invalide : '\(startStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM"))
        }

        guard EventDateParser.parseDate(endStr) != nil else {
            return .failure(ParseError(message: "date de fin invalide : '\(endStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM"))
        }

        return .success(CreateEventArgs(
            title: title,
            startStr: startStr,
            endStr: endStr,
            calendarId: options["--calendar-id"],
            calendarName: options["--calendar"],
            location: options["--location"],
            notes: options["--notes"],
            recurrence: options["--recurrence"],
            useJSON: flags.contains("--json")
        ))
    }
}
