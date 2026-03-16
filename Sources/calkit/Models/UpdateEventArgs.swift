import Foundation

/// Parsed arguments for the `events update` command.
struct UpdateEventArgs {
    let id: String
    let title: String?
    let startStr: String?
    let endStr: String?
    let location: String?
    let notes: String?
    let useJSON: Bool

    /// Parse raw CLI arguments into UpdateEventArgs.
    /// Returns .failure with an error message if required args are missing or invalid.
    static func parse(_ args: [String]) -> Result<UpdateEventArgs, ParseError> {
        // Extract positional args (skip flags and their values)
        var positional: [String] = []
        var options: [String: String] = [:]
        var flags: Set<String> = []
        let valuedOptions: Set<String> = ["--title", "--start", "--end", "--location", "--notes"]

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

        // ID is the first positional argument
        guard let id = positional.first, !id.isEmpty else {
            return .failure(ParseError(message: "identifiant manquant. Usage : calkit events update <id> [--title <titre>] [--start <datetime>] [--end <datetime>] [--location <lieu>] [--notes <texte>]"))
        }

        // At least one field must be provided
        let hasField = options["--title"] != nil || options["--start"] != nil
            || options["--end"] != nil || options["--location"] != nil || options["--notes"] != nil
        guard hasField else {
            return .failure(ParseError(message: "aucun champ à modifier. Fournissez au moins une option : --title, --start, --end, --location, --notes"))
        }

        // Validate date formats if provided
        if let startStr = options["--start"] {
            guard EventDateParser.parseDate(startStr) != nil else {
                return .failure(ParseError(message: "date de début invalide : '\(startStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM"))
            }
        }

        if let endStr = options["--end"] {
            guard EventDateParser.parseDate(endStr) != nil else {
                return .failure(ParseError(message: "date de fin invalide : '\(endStr)'. Format attendu : YYYY-MM-DDTHH:MM:SS ou YYYY-MM-DDTHH:MM"))
            }
        }

        return .success(UpdateEventArgs(
            id: id,
            title: options["--title"],
            startStr: options["--start"],
            endStr: options["--end"],
            location: options["--location"],
            notes: options["--notes"],
            useJSON: flags.contains("--json")
        ))
    }
}
