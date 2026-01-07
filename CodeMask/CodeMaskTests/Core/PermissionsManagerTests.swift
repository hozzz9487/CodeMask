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
    
    func testCheckInputMonitoring_ReturnsFalseInitially() {
        // In a test environment (and simulator), Input Monitoring is usually false/restricted.
        // We verify that the check returns false when permissions are not explicitly granted.
        let status = sut.checkInputMonitoring()
        XCTAssertFalse(status, "Input Monitoring should be false by default in test/sandbox environment")
    }
}
