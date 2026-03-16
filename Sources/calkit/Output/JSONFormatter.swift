import Foundation

enum JSONFormatter {
    /// Format any Encodable value as pretty-printed JSON string.
    static func format<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    /// Format a deleted event confirmation as JSON.
    static func formatDeletedEvent(id: String, title: String, span: String) -> String {
        let result = CKDeleteResult(id: id, title: title, span: span, deleted: true)
        return format(result)
    }
}
