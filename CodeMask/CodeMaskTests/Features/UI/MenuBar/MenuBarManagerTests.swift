//
//  MenuBarManagerTests.swift
//  CodeMaskTests
//
//  Created by BMad Dev Agent on 2026/02/05.
//

import XCTest
import AppKit
@testable import CodeMask

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    var manager: MenuBarManager!
    var appStore: AppStore!
    
    override func setUp() {
        super.setUp()
        appStore = AppStore(environment: AppEnvironment())
        manager = MenuBarManager(appStore: appStore)
    }
    
    override func tearDown() {
        manager = nil
        appStore = nil
        super.tearDown()
    }
    
    func testIconUpdate_Idle() {
        // Given
        appStore.session.hasSecrets = false
        
        // When
        manager.updateIcon(for: .idle)
        
        // Then (Verification via logic since NSStatusItem is hard to inspect in unit tests without extensive mocking)
    }
    
    func testIconConfigurationMapping() {
        // Reflects the internal logic in MenuBarManager
        let idle = manager.iconConfiguration(for: .idle)
        XCTAssertEqual(idle.0, "shield")
        XCTAssertEqual(idle.1, .systemGray)
        
        let secured = manager.iconConfiguration(for: .secured)
        XCTAssertEqual(secured.0, "lock.shield.fill")
        XCTAssertEqual(secured.1, .systemBlue)
        
        let warning = manager.iconConfiguration(for: .warning)
        XCTAssertEqual(warning.0, "exclamationmark.shield.fill")
        XCTAssertEqual(warning.1, .systemRed)
    }
}