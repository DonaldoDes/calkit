import Foundation

/// Parsed arguments for the `reminders set-url` command.
struct SetURLArgs {
    let title: String
    let url: String

    /// Parse raw CLI arguments into SetURLArgs.
    /// Expected: <titre> <url>
    static func parse(_ args: [String]) -> Result<SetURLArgs, ParseError> {
        guard args.count >= 1, let title = args.first, !title.isEmpty else {
            return .failure(ParseError(message: "titre manquant. Usage : calkit reminders set-url <titre> <url>"))
        }

        guard args.count >= 2 else {
            return .failure(ParseError(message: "url manquante. Usage : calkit reminders set-url <titre> <url>"))
        }

        let urlStr = args[1]
        guard URL(string: urlStr) != nil, urlStr.contains(":") else {
            return .failure(ParseError(message: "URL invalide : '\(urlStr)'. Format attendu : https://example.com"))
        }

        return .success(SetURLArgs(title: title, url: urlStr))
    }
}
