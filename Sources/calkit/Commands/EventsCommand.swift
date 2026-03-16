import Foundation

/// Shared helpers used by EventsReadCommand and EventsWriteCommand.
enum EventsHelpers {
    /// Output events in text or JSON format and exit.
    static func outputEvents(_ events: [CKEvent], useJSON: Bool) {
        if useJSON {
            print(JSONFormatter.format(events))
        } else {
            print(TextFormatter.formatEventsText(events, groupByDay: true))
        }
        exit(0)
    }

    /// Extract the value of a named option like --calendar <name>.
    static func extractOption(_ name: String, from args: [String]) -> String? {
        guard let index = args.firstIndex(of: name), index + 1 < args.count else {
            return nil
        }
        return args[index + 1]
    }

    /// Extract positional arguments (skip flags and their values).
    static func extractPositionalArgs(_ args: [String]) -> [String] {
        var result: [String] = []
        var i = 0
        while i < args.count {
            if args[i] == "--calendar" || args[i] == "--from" || args[i] == "--to" {
                i += 2 // skip flag + value
            } else if args[i].hasPrefix("--") {
                i += 1 // skip boolean flag
            } else {
                result.append(args[i])
                i += 1
            }
        }
        return result
    }
}
