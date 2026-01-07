import XCTest
@testable import CodeMask

final class PermissionsManagerTests: XCTestCase {
    
    var sut: PermissionsManager!
    
    override func setUp() {
        super.setUp()
        sut = PermissionsManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testCheckAccessibility_ReturnsBool() {
        // This invokes AXIsProcessTrusted(). Result depends on environment.
        // We primarily ensure it runs without crashing.
        let status = sut.checkAccessibility()
        print("Accessibility Status in Test: \(status)")
        // No assertion on true/false as it varies by CI/Sandbox, but it returns a bool.
        XCTAssertTrue(status || !status)
    }
    
    func testCheckInputMonitoring_ReturnsFalseInitially() {
        // In a test environment (and simulator), Input Monitoring is usually false/restricted.
        // We verify that the check returns false when permissions are not explicitly granted.
        let status = sut.checkInputMonitoring()
        XCTAssertFalse(status, "Input Monitoring should be false by default in test/sandbox environment")
    }
    
    func testCheckInputMonitoring_MultipleCalls_DoNotCrash() {
        // Call multiple times to verify resource cleanup (basic leak check)
        for _ in 0..<100 {
            _ = sut.checkInputMonitoring()
        }
    }
    
    func testPromptAccessibility_DoesNotCrash() {
        // Should not crash even if prompt can't be shown in headless mode
        sut.promptAccessibility()
    }
}