import Foundation

// Shared test framework for standalone swiftc compilation (no XCTest dependency)
var testCount = 0
var failCount = 0
var currentTest = ""

func runTest(_ name: String, _ body: () -> Void) {
    currentTest = name
    testCount += 1
    body()
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "", file: String = #file, line: Int = #line) {
    if a != b {
        failCount += 1
        let extra = msg.isEmpty ? "" : " — \(msg)"
        FileHandle.standardError.write(Data("FAIL [\(currentTest)] \(file):\(line): \(a) != \(b)\(extra)\n".utf8))
    }
}

func assertTrue(_ condition: Bool, _ msg: String = "", file: String = #file, line: Int = #line) {
    if !condition {
        failCount += 1
        let extra = msg.isEmpty ? "" : " — \(msg)"
        FileHandle.standardError.write(Data("FAIL [\(currentTest)] \(file):\(line): assertion false\(extra)\n".utf8))
    }
}

func assertFalse(_ condition: Bool, _ msg: String = "", file: String = #file, line: Int = #line) {
    assertTrue(!condition, msg, file: file, line: line)
}

func reportResults() {
    print("")
    if failCount > 0 {
        print("\(failCount) failure(s) out of \(testCount) tests.")
        exit(1)
    } else {
        print("All \(testCount) tests passed.")
        exit(0)
    }
}
