import XCTest
@testable import CodeMask

@MainActor
final class HotkeysTests: XCTestCase {
    func testHotkeysNamespaceStructure() {
        // Verify State struct exists
        let state = Hotkeys.State()
        XCTAssertFalse(state.isMaskingRegistered)
        XCTAssertFalse(state.isRestorationRegistered)
        XCTAssertNil(state.lastError)
        XCTAssertNil(state.lastTriggeredHotkey)
        XCTAssertNil(state.lastHotkeyTriggerTime)
        
        // Verify Action cases exist
        XCTAssertEqual(Hotkeys.Action.didTriggerMasking, Hotkeys.Action.didTriggerMasking)
        XCTAssertEqual(Hotkeys.Action.didTriggerRestoration, Hotkeys.Action.didTriggerRestoration)
        XCTAssertEqual(Hotkeys.Action.didFailToRegister(.unknown), Hotkeys.Action.didFailToRegister(.unknown))
    }
    
    func testAppStoreIntegration_Error() {
        // Verify AppStore has hotkeys state
        let store = AppStore.shared
        XCTAssertNotNil(store.hotkeys)
        
        // Simulate a hotkey error action
        let error = AppError.hotkeyConflict(hotkeyName: "Test")
        store.send(.hotkeys(.didFailToRegister(error)))
        XCTAssertEqual(store.hotkeys.lastError, error)
    }
    
    func testAppStoreIntegration_Trigger() {
        let store = AppStore.shared
        
        // Simulate masking trigger
        store.send(.hotkeys(.didTriggerMasking))
        XCTAssertEqual(store.hotkeys.lastTriggeredHotkey, .didTriggerMasking)
        XCTAssertNotNil(store.hotkeys.lastHotkeyTriggerTime)
        
        let firstTriggerTime = store.hotkeys.lastHotkeyTriggerTime!
        
        // Simulate restoration trigger
        store.send(.hotkeys(.didTriggerRestoration))
        XCTAssertEqual(store.hotkeys.lastTriggeredHotkey, .didTriggerRestoration)
        XCTAssertGreaterThanOrEqual(store.hotkeys.lastHotkeyTriggerTime!, firstTriggerTime)
    }
}