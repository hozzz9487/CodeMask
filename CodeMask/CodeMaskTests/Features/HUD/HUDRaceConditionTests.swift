//
//  HUDRaceConditionTests.swift
//  CodeMaskTests
//
//  Created by AI on 2026/1/30.
//

import XCTest
@testable import CodeMask

@MainActor
final class HUDRaceConditionTests: XCTestCase {
    
    func testHUD_MultipleShowCalls_CancelsAutoHideCorrectly() async throws {
        // GIVEN: Fresh AppStore with mock environment
        let store = AppStore(environment: AppEnvironment())
        
        // WHEN: Show HUD first time
        store.send(.hud(.show(message: "First", type: .success)))
        XCTAssertEqual(store.hud.message, "First")
        XCTAssertTrue(store.hud.isVisible)
        
        // Wait a short time (less than auto-hide duration)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // WHEN: Show HUD second time (race condition trigger)
        store.send(.hud(.show(message: "Second", type: .error)))
        XCTAssertEqual(store.hud.message, "Second")
        XCTAssertTrue(store.hud.isVisible)
        
        // THEN: Wait for first auto-hide timer (should be cancelled)
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1s (past first timer)
        
        // HUD should STILL be visible because first timer was cancelled
        XCTAssertTrue(store.hud.isVisible, "HUD disappeared prematurely - first auto-hide task was not cancelled")
        XCTAssertEqual(store.hud.message, "Second")
        
        // THEN: Wait for second auto-hide timer to complete
        try await Task.sleep(nanoseconds: 500_000_000) // Additional 0.5s (total 1.5s from second show)
        
        // Now HUD should be hidden
        XCTAssertFalse(store.hud.isVisible, "HUD should be hidden after second timer completes")
        XCTAssertEqual(store.hud.message, "")
    }
    
    func testHUD_TripleShowCalls_OnlyLastTimerExecutes() async throws {
        // GIVEN: Fresh AppStore
        let store = AppStore(environment: AppEnvironment())
        
        // WHEN: Rapid triple show
        store.send(.hud(.show(message: "A", type: .success)))
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        store.send(.hud(.show(message: "B", type: .success)))
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        store.send(.hud(.show(message: "C", type: .success)))
        
        // THEN: Wait 1.2s (should still be visible)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertTrue(store.hud.isVisible, "HUD disappeared - early timers not cancelled")
        XCTAssertEqual(store.hud.message, "C")
        
        // Wait another 0.4s (total 1.6s from last show)
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertFalse(store.hud.isVisible)
    }
}
