//
//  GuardianStateTests.swift
//  CodeMaskTests
//
//  Created by Edison on 2026/2/12.
//

import XCTest
@testable import CodeMask

@MainActor
final class GuardianStateTests: XCTestCase {
    
    var store: AppStore!
    var mockDetector: MockBrowserContextDetector!
    
    override func setUp() {
        super.setUp()
        let environment = AppEnvironment(
            browserContextDetector: MockBrowserContextDetector()
        )
        // Extract reference to mock for manipulation
        self.mockDetector = environment.browserContextDetector as? MockBrowserContextDetector
        
        // Create fresh store
        store = AppStore(environment: environment)
    }
    
    override func tearDown() {
        store = nil
        mockDetector = nil
        super.tearDown()
    }
    
    func testAppStoreStartsMonitoringOnInit() {
        // Given/When - init called in setUp
        
        // Then
        let expectation = XCTestExpectation(description: "Monitoring started")
        
        Task {
            // Give time for init task specific to browser observation to run
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            if self.mockDetector.isMonitoring {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBrowserActivationUpdatesState() async {
        // Given
        store.guardian = Guardian.State() // Reset state
        
        // When
        store.send(.guardian(.didActivateBrowserApp(bundleID: "com.apple.Safari")))
        
        // Then
        XCTAssertTrue(store.guardian.isBrowserFocused)
        XCTAssertEqual(store.guardian.activeBrowserBundleID, "com.apple.Safari")
    }
    
    func testBrowserDeactivationUpdatesState() async {
        // Given
        store.guardian.isBrowserFocused = true
        store.guardian.activeBrowserBundleID = "com.apple.Safari"
        
        // When
        store.send(.guardian(.didDeactivateBrowserApp))
        
        // Then
        XCTAssertFalse(store.guardian.isBrowserFocused)
        XCTAssertNil(store.guardian.activeBrowserBundleID)
    }
    
    func testDangerState_BrowserActiveAndSecrets_TriggersDanger() async {
        // Given
        store.guardian.isBrowserFocused = true
        store.session.hasSecrets = true
        store.session.isDanger = false
        
        // When
        // Simulate event: Browser Activation while secrets present
        store.send(.guardian(.didActivateBrowserApp(bundleID: "browser")))
        
        // Then
        XCTAssertTrue(store.session.isDanger)
    }
    
    func testDangerState_BrowserDeactivation_ClearsDanger() async {
        // Given
        store.guardian.isBrowserFocused = true
        store.session.hasSecrets = true
        store.session.isDanger = true
        
        // When
        store.send(.guardian(.didDeactivateBrowserApp))
        
        // Then
        XCTAssertFalse(store.session.isDanger)
    }
    
    func testDangerState_SecretsCheck_TriggersDanger() async {
        // Given
        store.guardian.isBrowserFocused = true
        store.session.hasSecrets = true
        store.session.isDanger = false
        
        // When
        // Directly test the evaluation logic
        store.evaluateDangerState()
        
        // Then
        XCTAssertTrue(store.session.isDanger)
    }

    func testDetectorEventStream_UpdatesStoreState() async {
        // Given
        store.guardian = Guardian.State()
        
        // When
        mockDetector.simulateEvent(.didActivateBrowserApp(bundleID: "com.apple.Safari"))
        try? await Task.sleep(nanoseconds: 50_000_000) // Allow event loop to process
        
        // Then
        XCTAssertTrue(store.guardian.isBrowserFocused)
        XCTAssertEqual(store.guardian.activeBrowserBundleID, "com.apple.Safari")
    }

    func testDetectorRapidSwitching_DoesNotLeaveStaleState() async {
        // Given
        store.guardian = Guardian.State()
        
        // When
        mockDetector.simulateEvent(.didActivateBrowserApp(bundleID: "com.apple.Safari"))
        mockDetector.simulateEvent(.didDeactivateBrowserApp)
        mockDetector.simulateEvent(.didActivateBrowserApp(bundleID: "com.google.Chrome"))
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertTrue(store.guardian.isBrowserFocused)
        XCTAssertEqual(store.guardian.activeBrowserBundleID, "com.google.Chrome")
    }

    func testUpdateHasSecrets_ClearsDangerWhenBrowserActive() async {
        // Given
        store.guardian.isBrowserFocused = true
        store.session.hasSecrets = true
        store.session.isDanger = true
        
        // When
        store.updateHasSecrets(false)
        
        // Then
        XCTAssertFalse(store.session.isDanger)
        XCTAssertFalse(store.session.hasSecrets)
    }
}
