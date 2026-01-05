//
//  AppStoreTests.swift
//  CodeMaskTests
//
//  Created by Edison on 2026/1/5.
//

import XCTest
@testable import CodeMask

@MainActor
final class AppStoreTests: XCTestCase {

    func testInitialState() {
        let store = AppStore(environment: AppEnvironment())
        XCTAssertFalse(store.isSafe, "Should strictly default to unsafe")
    }
    
    func testSecurityActionUpdatesState() {
        let store = AppStore(environment: AppEnvironment())
        
        // When: Accessibility is granted
        store.send(.security(.permissions(.didCheckStatus(accessibility: true, inputMonitoring: true))))
        
        // Then: App should be safe
        XCTAssertTrue(store.isSafe)
        XCTAssertTrue(store.security.permissions.isAccessibilityGranted)
    }
    
    func testPartialPermissionsAreUnsafe() {
        let store = AppStore(environment: AppEnvironment())
        
        store.send(.security(.permissions(.didCheckStatus(accessibility: true, inputMonitoring: false))))
        XCTAssertFalse(store.isSafe)
        
        store.send(.security(.permissions(.didCheckStatus(accessibility: false, inputMonitoring: true))))
        XCTAssertFalse(store.isSafe)
    }
}
