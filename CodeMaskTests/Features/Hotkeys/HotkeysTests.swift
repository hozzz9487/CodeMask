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
        
        // Verify Action cases exist
        let _ = Hotkeys.Action.didTriggerMasking
        let _ = Hotkeys.Action.didTriggerRestoration
        let _ = Hotkeys.Action.didFailToRegister(.unknown)
    }
    
    func testAppStoreIntegration() {
        // Verify AppStore has hotkeys state
        let store = AppStore.shared
        XCTAssertNotNil(store.hotkeys)
        
        // Simulate a hotkey error action
        store.send(.hotkeys(.didFailToRegister(.unknown)))
        XCTAssertEqual(store.hotkeys.lastError, .unknown)
    }
}