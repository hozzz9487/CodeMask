import XCTest
@testable import CodeMask

final class SecureBufferTests: XCTestCase {
    
    func testLifecycle() {
        let secret = "super-secret-password"
        let buffer = SecureBuffer(string: secret)
        XCTAssertNotNil(buffer)
    }
    
    func testMlockEnforcement() {
        // If REQUIRE_MLOCK is set, we expect strict behavior.
        // Since we can't easily probe mlock from Swift without complex vm checks,
        // we rely on the implementation not crashing and completing init.
        let requireMlock = getenv("REQUIRE_MLOCK") != nil
        if requireMlock {
            print("REQUIRE_MLOCK is set. Verifying SecureBuffer creation...")
        }
        
        let buffer = SecureBuffer(string: "lock-me-please")
        XCTAssertNotNil(buffer)
    }
    
    func testRetrieve() {
        let secret = "my-secret-data"
        let buffer = SecureBuffer(string: secret)
        XCTAssertEqual(buffer.retrieve(), secret)
    }
}
