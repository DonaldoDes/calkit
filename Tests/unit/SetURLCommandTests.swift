import Foundation

@main
struct SetURLTestRunner {
    static func main() {

        // --- SetURLArgs tests ---

        runTest("set-url: parse valid args") {
            let result = SetURLArgs.parse(["Mon rappel", "https://example.com"])
            switch result {
            case .success(let args):
                assertEqual(args.title, "Mon rappel")
                assertEqual(args.url, "https://example.com")
            case .failure(let err):
                assertTrue(false, "unexpected failure: \(err.message)")
            }
        }

        runTest("set-url: parse missing title") {
            let result = SetURLArgs.parse([])
            switch result {
            case .success:
                assertTrue(false, "should fail with empty args")
            case .failure(let err):
                assertTrue(err.message.contains("titre"), "error should mention titre: \(err.message)")
            }
        }

        runTest("set-url: parse missing url") {
            let result = SetURLArgs.parse(["Mon rappel"])
            switch result {
            case .success:
                assertTrue(false, "should fail with missing url")
            case .failure(let err):
                assertTrue(err.message.contains("url") || err.message.contains("URL"), "error should mention url: \(err.message)")
            }
        }

        runTest("set-url: parse invalid url") {
            let result = SetURLArgs.parse(["Mon rappel", "not-a-url"])
            switch result {
            case .success:
                assertTrue(false, "should fail with invalid url")
            case .failure(let err):
                assertTrue(err.message.contains("URL"), "error should mention URL: \(err.message)")
            }
        }

        // --- ShortcutsService.buildInput tests ---

        runTest("buildInput: formats title|||url") {
            let input = ShortcutsService.buildInput(title: "Acheter du pain", url: "https://example.com")
            assertEqual(input, "Acheter du pain|||https://example.com")
        }

        runTest("buildInput: handles special characters in title") {
            let input = ShortcutsService.buildInput(title: "Réunion d'équipe", url: "https://meet.google.com/abc")
            assertEqual(input, "Réunion d'équipe|||https://meet.google.com/abc")
        }

        reportResults()
    }
}
