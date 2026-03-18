import Foundation

@main
struct CreateReminderListTestRunner {
    static func main() {

        // === CreateReminderListArgs parsing ===

        runTest("parseCreateReminderListArgs_validName") {
            let args = ["Brio"]
            let result = CreateReminderListArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.name, "Brio")
                assertFalse(parsed.useJSON, "Default should not use JSON")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseCreateReminderListArgs_validNameWithJSON") {
            let args = ["Courses", "--json"]
            let result = CreateReminderListArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.name, "Courses")
                assertTrue(parsed.useJSON, "Should enable JSON output")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        runTest("parseCreateReminderListArgs_missingName") {
            let args: [String] = []
            let result = CreateReminderListArgs.parse(args)
            switch result {
            case .success:
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] should have failed for missing name\n".utf8))
            case .failure(let err):
                assertTrue(err.message.contains("nom"), "Error should mention missing name: \(err.message)")
            }
        }

        runTest("parseCreateReminderListArgs_nameWithSpaces") {
            let args = ["Liste de courses"]
            let result = CreateReminderListArgs.parse(args)
            switch result {
            case .success(let parsed):
                assertEqual(parsed.name, "Liste de courses")
            case .failure(let err):
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] unexpected error: \(err.message)\n".utf8))
            }
        }

        // === JSON formatter for create-list result ===

        runTest("formatCreateReminderListJSON_created") {
            let result = CKCreateReminderListResult(name: "Brio", id: "cal-123", created: true)
            let json = JSONFormatter.format(result)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["name"] as? String ?? "", "Brio")
            assertEqual(parsed["id"] as? String ?? "", "cal-123")
            assertEqual(parsed["created"] as? Bool ?? false, true)
        }

        runTest("formatCreateReminderListJSON_alreadyExists") {
            let result = CKCreateReminderListResult(name: "Courses", id: "cal-456", created: false)
            let json = JSONFormatter.format(result)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed["name"] as? String ?? "", "Courses")
            assertEqual(parsed["id"] as? String ?? "", "cal-456")
            assertEqual(parsed["created"] as? Bool ?? true, false)
        }

        runTest("formatCreateReminderListJSON_hasThreeKeys") {
            let result = CKCreateReminderListResult(name: "Test", id: "x", created: true)
            let json = JSONFormatter.format(result)
            guard let data = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                failCount += 1
                FileHandle.standardError.write(Data("FAIL [\(currentTest)] Output should be valid JSON object\n".utf8))
                return
            }
            assertEqual(parsed.count, 3, "JSON should have exactly 3 keys: name, id, created")
        }

        reportResults()
    }
}
