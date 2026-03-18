import Foundation

/// Parsed arguments for the `reminders complete` command.
struct CompleteReminderArgs {
    let id: String
    let useJSON: Bool

    /// Parse raw CLI arguments into CompleteReminderArgs.
    /// Returns .failure if the required ID is missing.
    static func parse(_ args: [String]) -> Result<CompleteReminderArgs, ParseError> {
        var positional: [String] = []
        var flags: Set<String> = []

        var i = 0
        while i < args.count {
            let arg = args[i]
            if arg.hasPrefix("--") {
                flags.insert(arg)
                i += 1
            } else {
                positional.append(arg)
                i += 1
            }
        }

        guard let id = positional.first, !id.isEmpty else {
            return .failure(ParseError(message: "identifiant manquant. Usage : calkit reminders complete <id> [--json]"))
        }

        return .success(CompleteReminderArgs(id: id, useJSON: flags.contains("--json")))
    }
}
