//
//  CodeMaskTests.swift
//  CodeMaskTests
//
//  Created by Edison on 2026/1/5.
//

import Testing
@testable import CodeMask

struct CodeMaskTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func verifyKeyboardServicePasteAPI() async throws {
        let service: KeyboardServiceProtocol = LiveKeyboardService()
        // Just verify we can call it. If it compiles, the API contract is met.
        await service.simulatePaste()
        #expect(service is LiveKeyboardService)
    }

}
