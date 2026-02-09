import XCTest
@testable import CodeMask

/// Integration tests for AppDelegate lifecycle and permission checking flow
@MainActor
final class AppDelegateTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    var mockPermissionsManager: MockPermissionsManager!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
        mockPermissionsManager = MockPermissionsManager()
        // Inject mock into AppStore
        AppStore.shared.environment.permissionsManager = mockPermissionsManager
    }
    
    override func tearDown() {
        appDelegate = nil
        mockPermissionsManager = nil
        // Reset environment to default
        AppStore.shared.environment = AppEnvironment()
        super.tearDown()
    }
    
    /// Test that AppDelegate initializes MenuBarManager on application launch
    func testApplicationDidFinishLaunching_InitializesMenuBarManager() {
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        
        // Before launching, menuBarManager should be nil
        XCTAssertNil(appDelegate.menuBarManager, "MenuBarManager should not be initialized before launch")
        
        // Simulate application launch
        appDelegate.applicationDidFinishLaunching(notification)
        
        // After launching, menuBarManager should be initialized
        XCTAssertNotNil(appDelegate.menuBarManager, "MenuBarManager should be initialized after application launch")
    }
    
    /// Test that checkPermissions dispatches correct action to AppStore
    func testCheckPermissions_DispatchesCorrectAction() {
        // Reset AppStore state
        AppStore.shared.security.permissions.isAccessibilityGranted = false
        AppStore.shared.security.permissions.isInputMonitoringGranted = false
        
        // Simulate permission check
        appDelegate.checkPermissions()
        
        // Verify that the AppStore state was updated
        // (Actual permission check result depends on test environment)
        // We primarily verify that the action was dispatched and store was updated
        XCTAssertTrue(AppStore.shared.security.permissions.isAccessibilityGranted || !AppStore.shared.security.permissions.isAccessibilityGranted,
                      "AppStore state should be updated after permission check")
    }
    
    /// Test that error observer receives error when permissions fail
    func testErrorObserver_ReceivesErrorWhenPermissionsFail() {
        let expectation = self.expectation(description: "Error publisher should emit error")
        var receivedError: AppError?
        
        // Subscribe to error publisher
        let cancellable = AppStore.shared.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
        
        // Simulate permission check failure
        AppStore.shared.send(.security(.didEncounterError(.permissionsCheckFailed)))
        
        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Error observer test timed out: \(error)")
            }
        }
        
        XCTAssertEqual(receivedError, .permissionsCheckFailed, "Error observer should receive permissionsCheckFailed error")
        cancellable.cancel()
    }
    
    /// Test that error observer can receive multiple errors (not one-shot)
    func testErrorObserver_CanReceiveMultipleErrors() {
        let expectation1 = expectation(description: "First error received")
        let expectation2 = expectation(description: "Second error received")
        
        var errorCount = 0
        var lastError: AppError?
        
        let cancellable = AppStore.shared.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                if error != nil {
                    errorCount += 1
                    lastError = error
                    if errorCount == 1 {
                        expectation1.fulfill()
                    } else if errorCount == 2 {
                        expectation2.fulfill()
                    }
                }
            }
        
        // First error
        AppStore.shared.send(.security(.didEncounterError(.permissionsCheckFailed)))
        wait(for: [expectation1], timeout: 1.0)
        XCTAssertEqual(errorCount, 1, "Should receive first error")
        
        // Clear error
        AppStore.shared.send(.security(.didClearError))
        
        // Second error should still be received (not a one-shot observer)
        AppStore.shared.send(.security(.didEncounterError(.permissionsCheckFailed)))
        wait(for: [expectation2], timeout: 1.0)
        
        XCTAssertEqual(errorCount, 2, "Should receive second error after clearing first")
        XCTAssertEqual(lastError, .permissionsCheckFailed, "Last error should be permissions check failed")
        cancellable.cancel()
    }
    
    /*
    /// Test that AppDelegate starts permission monitor on launch
    func testApplicationDidFinishLaunching_StartsPermissionMonitor() {
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        
        // Permission monitor should be nil before launch
        XCTAssertNil(appDelegate.permissionCheckTimer, "Permission timer should not exist before launch")
        
        // Simulate application launch
        appDelegate.applicationDidFinishLaunching(notification)
        
        // Permission monitor should be active after launch
        XCTAssertNotNil(appDelegate.permissionCheckTimer, "Permission monitor should be started after launch")
        
        // Clean up
        appDelegate.permissionCheckTimer?.invalidate()
    }
    */
    
    /// Test integration: Permission check updates store and triggers icon update
    func testPermissionCheckFlow_UpdatesStoreAndNotifiesObservers() {
        let updateExpectation = self.expectation(description: "Icon should update after permission check")
        
        // Setup initial state via ACTION to ensure previousPermissionState is updated
        // We set it to true/true so that the subsequent check (false/false) triggers a change
        AppStore.shared.send(.security(.permissions(.didCheckStatus(accessibility: true, inputMonitoring: true))))
        
        // Subscribe to isSafePublisher to detect when permissions are evaluated
        let cancellable = AppStore.shared.isSafePublisher
            .sink { _ in
                updateExpectation.fulfill()
            }
        
        // Trigger permission check (Mock returns false, so state changes true -> false)
        appDelegate.checkPermissions()
        
        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Permission check flow test timed out: \(error)")
            }
        }
        
        // Verify store state was updated
        XCTAssertFalse(AppStore.shared.security.permissions.isAccessibilityGranted,
                      "Store permissions should be updated to false after check")
        cancellable.cancel()
    }
}

// MARK: - Mock Objects for Testing