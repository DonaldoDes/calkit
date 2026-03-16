import Foundation

/// Parsed arguments for the `events delete` command.
struct DeleteEventArgs {
    let id: String
    let span: String  // "thisEvent" or "futureEvents"

    /// Valid span values.
    private static let validSpans: Set<String> = ["thisEvent", "futureEvents"]

    /// Parse raw CLI arguments into DeleteEventArgs.
    /// Returns .failure with an error message if required args are missing or invalid.
    static func parse(_ args: [String]) -> Result<DeleteEventArgs, ParseError> {
        var positional: [String] = []
        var options: [String: String] = [:]
        let valuedOptions: Set<String> = ["--span"]

        var i = 0
        while i < args.count {
            let arg = args[i]
            if valuedOptions.contains(arg) {
                guard i + 1 < args.count else {
                    return .failure(ParseError(message: "option '\(arg)' necessite une valeur."))
                }
                options[arg] = args[i + 1]
                i += 2
            } else if arg.hasPrefix("--") {
                // Boolean flags (none expected for delete, but skip gracefully)
                i += 1
            } else {
                positional.append(arg)
                i += 1
            }
        }

        // ID is the first positional argument
        guard let id = positional.first, !id.isEmpty else {
            return .failure(ParseError(message: "identifiant manquant. Usage : calkit events delete <id> [--span thisEvent|futureEvents]"))
        }

        // Span validation
        let span = options["--span"] ?? "thisEvent"
        guard validSpans.contains(span) else {
            return .failure(ParseError(message: "valeur --span invalide : '\(span)'. Valeurs autorisees : thisEvent, futureEvents"))
        }

        return .success(DeleteEventArgs(id: id, span: span))
    }
}
