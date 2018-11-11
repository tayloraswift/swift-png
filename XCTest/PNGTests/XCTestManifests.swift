import XCTest

extension APITests {
    static let __allTests = [
        ("testPNG", testPNG),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(APITests.__allTests),
    ]
}
#endif
