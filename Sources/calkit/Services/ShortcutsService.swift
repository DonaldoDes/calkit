import Foundation

/// Bridges calkit to the Shortcuts.app "calkit-set-url" shortcut
/// to set the new Reminders URL field (CloudKit, iOS 16+) that EventKit cannot write.
enum ShortcutsService {

    static let shortcutName = "calkit-set-url"

    /// Build the stdin input string for the calkit-set-url shortcut.
    /// Format: "title|||url"
    static func buildInput(title: String, url: String) -> String {
        return "\(title)|||\(url)"
    }

    /// Sets the URL on a reminder via the calkit-set-url Shortcuts shortcut.
    /// Fire-and-forget: does not block on failure.
    /// - Parameters:
    ///   - title: Title of the reminder to update
    ///   - url: URL to set (new Reminders URL field)
    static func setReminderURL(title: String, url: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcutName, "--input-path", "-"]

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        // Suppress stdout/stderr from shortcuts run
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let input = buildInput(title: title, url: url)
            if let data = input.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
            }
            inputPipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
        } catch {
            // Non-fatal: EventKit URL is still set, just not the CloudKit one
        }
    }
}
