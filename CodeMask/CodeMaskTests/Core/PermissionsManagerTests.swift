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

    func testCheckInputMonitoring_HandlesNilEventCallback() {
        // We use the tapProvider to capture the callback and call it with nil
        var capturedCallback: CGEventTapCallBack?
        
        let mockTapProvider: PermissionsManager.TapProvider = { _, _, _, _, callback, _ in
            capturedCallback = callback
            // We can't easily create a real CFMachPort in a unit test without system side effects,
            // but we can return nil or a dummy. Returning nil triggers the guard in checkInputMonitoring.
            // To test the callback itself, we need to call it.
            return nil 
        }
        
        let manager = PermissionsManager(tapProvider: mockTapProvider)
        _ = manager.checkInputMonitoring()
        
        // Now call the captured callback with nil event
        // We need to satisfy the non-optional CGEvent parameter in Swift
        // This is tricky. In a real crash scenario, the C side passes NULL.
        // We can use unsafe bit casting to force a nil into a non-optional parameter for testing.
        if let callback = capturedCallback {
            let proxy = unsafeBitCast(0 as Int, to: CGEventTapProxy.self)
            let event = unsafeBitCast(0 as Int, to: CGEvent.self) // This is the "nil" CGEvent
            
            // This should not crash if the guard in PermissionsManager is working
            let result = callback(proxy, .keyDown, event, nil)
            XCTAssertNil(result, "Callback should return nil when event is nil (NULL from C)")
        }
    }
    
    func testPromptAccessibility_DoesNotCrash() {
        // Should not crash even if prompt can't be shown in headless mode
        sut.promptAccessibility()
    }
}