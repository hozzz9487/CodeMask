
//
//  SessionStateTests.swift
//  CodeMaskTests
//
//  Created by BMad Dev Agent on 2026/02/05.
//

import XCTest
@testable import CodeMask

final class SessionStateTests: XCTestCase {
    
    func testSecurityStatusEnum() {
        // Verify enum definition
        let idle = Session.SecurityStatus.idle
        let secured = Session.SecurityStatus.secured
        let warning = Session.SecurityStatus.warning
        let unknown = Session.SecurityStatus.unknown
        
        XCTAssertEqual(idle, .idle)
        XCTAssertEqual(secured, .secured)
        XCTAssertEqual(warning, .warning)
        XCTAssertEqual(unknown, .unknown)
    }
    
    func testComputedSecurityStatus_Idle() {
        // Given
        var state = Session.State()
        state.hasSecrets = false
        
        // Then
        XCTAssertEqual(state.securityStatus, .idle)
    }
    
    func testComputedSecurityStatus_Secured() {
        // Given
        var state = Session.State()
        state.hasSecrets = true
        
        // Then
        XCTAssertEqual(state.securityStatus, .secured)
    }
    
    // Future test for Warning state
}
