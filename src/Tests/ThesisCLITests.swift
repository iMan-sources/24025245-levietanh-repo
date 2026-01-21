import XCTest

final class ThesisCLITests: XCTestCase {
    func testExample() {
        // This is an example test case
        XCTAssertTrue(true, "This test should always pass")
    }
    
    func testSwiftVersion() {
        // Test that we can detect Swift version
        let version = getSwiftVersion()
        XCTAssertFalse(version.isEmpty, "Swift version should not be empty")
    }
}

// Helper function for testing
func getSwiftVersion() -> String {
    #if swift(>=5.9)
    return "5.9+"
    #elseif swift(>=5.8)
    return "5.8+"
    #else
    return "Unknown"
    #endif
}
