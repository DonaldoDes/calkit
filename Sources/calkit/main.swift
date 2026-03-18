import Foundation

func printError(_ message: String) {
    FileHandle.standardError.write(Data("calkit: error: \(message)\n".utf8))
}

let args = Array(CommandLine.arguments.dropFirst())

// No arguments → show global help
if args.isEmpty {
    print(Help.global)
    exit(0)
}

let first = args[0]

// Global help flags
if first == "--help" || first == "-h" {
    print(Help.global)
    exit(0)
}

// Check if first arg is a known domain
if Help.validDomains.contains(first) {
    let domain = first
    let remaining = Array(args.dropFirst())

    // Domain with --help or no subcommand
    if remaining.isEmpty || remaining[0] == "--help" || remaining[0] == "-h" {
        if let helpText = Help.forDomain(domain) {
            print(helpText)
            exit(0)
        }
    }

    let action = remaining[0]
    let actionArgs = Array(remaining.dropFirst())

    // Route to command handlers
    switch (domain, action) {
    case ("calendars", "list"):
        CalendarsCommand.runList(args: actionArgs)
    case ("events", "today"):
        EventsReadCommand.runToday(args: actionArgs)
    case ("events", "range"):
        EventsReadCommand.runRange(args: actionArgs)
    case ("events", "search"):
        EventsReadCommand.runSearch(args: actionArgs)
    case ("events", "create"):
        EventsWriteCommand.runCreate(args: actionArgs)
    case ("events", "update"):
        EventsWriteCommand.runUpdate(args: actionArgs)
    case ("events", "delete"):
        EventsWriteCommand.runDelete(args: actionArgs)
    case ("reminders", "lists"):
        RemindersReadCommand.runLists(args: actionArgs)
    case ("reminders", "list"):
        RemindersReadCommand.runList(args: actionArgs)
    case ("reminders", "create-list"):
        RemindersWriteCommand.runCreateList(args: actionArgs)
    case ("reminders", "create"):
        RemindersWriteCommand.runCreate(args: actionArgs)
    case ("reminders", "complete"):
        RemindersWriteCommand.runComplete(args: actionArgs)
    case ("reminders", "delete"):
        RemindersWriteCommand.runDelete(args: actionArgs)
    case ("reminders", "set-url"):
        RemindersWriteCommand.runSetURL(args: actionArgs)
    default:
        printError("'\(domain) \(action)' n'est pas encore implémenté.")
        exit(1)
    }
}

// Unknown argument or domain
printError("commande inconnue : '\(first)'. Lancez 'calkit --help' pour l'aide.")
exit(1)
