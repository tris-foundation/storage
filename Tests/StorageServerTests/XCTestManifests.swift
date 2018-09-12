#if !os(macOS)
import XCTest

extension ServerTests {
    // DO NOT MODIFY: This is autogenerated, use: 
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ServerTests = [
        ("testBinaryProtocol", testBinaryProtocol),
        ("testHTTPFullStask", testHTTPFullStask),
        ("testHTTPHandler", testHTTPHandler),
        ("testServer", testServer),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ServerTests.__allTests__ServerTests),
    ]
}
#endif