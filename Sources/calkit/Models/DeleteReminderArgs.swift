import Foundation

/// Parsed arguments for the `reminders delete` command.
struct DeleteReminderArgs {
    let id: String
    let useJSON: Bool

    /// Parse raw CLI arguments into DeleteReminderArgs.
    /// Returns .failure if the required ID is missing.
    static func parse(_ args: [String]) -> Result<DeleteReminderArgs, ParseError> {
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
            return .failure(ParseError(message: "identifiant manquant. Usage : calkit reminders delete <id> [--json]"))
        }

        return .success(DeleteReminderArgs(id: id, useJSON: flags.contains("--json")))
    }
}
