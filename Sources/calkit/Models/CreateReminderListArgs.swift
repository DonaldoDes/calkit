import Foundation

/// Parsed arguments for the `reminders create-list` command.
struct CreateReminderListArgs {
    let name: String
    let useJSON: Bool

    /// Parse raw CLI arguments into CreateReminderListArgs.
    /// Returns .failure if the required name is missing.
    static func parse(_ args: [String]) -> Result<CreateReminderListArgs, ParseError> {
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

        guard let name = positional.first, !name.isEmpty else {
            return .failure(ParseError(message: "nom manquant. Usage : calkit reminders create-list <nom> [--json]"))
        }

        return .success(CreateReminderListArgs(name: name, useJSON: flags.contains("--json")))
    }
}

/// Result of creating a reminder list, for JSON output.
struct CKCreateReminderListResult: Encodable {
    let name: String
    let id: String
    let created: Bool
}
