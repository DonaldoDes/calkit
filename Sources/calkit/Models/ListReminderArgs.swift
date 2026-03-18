import Foundation

/// Parsed arguments for the `reminders list` command.
struct ListReminderArgs {
    let listName: String?
    let includeCompleted: Bool
    let dueBefore: String?
    let useJSON: Bool

    /// Parse raw CLI arguments into ListReminderArgs.
    /// This command has no required arguments — all are optional filters.
    static func parse(_ args: [String]) -> ListReminderArgs {
        var options: [String: String] = [:]
        var flags: Set<String> = []
        let valuedOptions: Set<String> = ["--list", "--due-before"]

        var i = 0
        while i < args.count {
            let arg = args[i]
            if valuedOptions.contains(arg) {
                if i + 1 < args.count {
                    options[arg] = args[i + 1]
                    i += 2
                } else {
                    i += 1
                }
            } else if arg.hasPrefix("--") {
                flags.insert(arg)
                i += 1
            } else {
                i += 1
            }
        }

        return ListReminderArgs(
            listName: options["--list"],
            includeCompleted: flags.contains("--completed"),
            dueBefore: options["--due-before"],
            useJSON: flags.contains("--json")
        )
    }
}
