
import XCTest
@testable import CodeMask

@MainActor
final class RestorationLoopTests: XCTestCase {
    
    var mockPasteboard: MockPasteboardService!
    var mockSession: MockSessionActor!
    var mockRegex: MockRegexEngine!
    var mockKeyboard: MockKeyboardService!
    var mockHaptics: MockHapticService!
    var mockAudio: MockAudioService!
    var appStore: AppStore!
    
    override func setUp() async throws {
        mockPasteboard = MockPasteboardService()
        mockSession = MockSessionActor()
        mockRegex = MockRegexEngine()
        mockKeyboard = MockKeyboardService()
        mockHaptics = MockHapticService()
        mockAudio = MockAudioService()
        
        let env = AppEnvironment(
            session: mockSession,
            pasteboard: mockPasteboard,
            haptics: mockHaptics,
            audio: mockAudio,
            regexEngine: mockRegex,
            keyboard: mockKeyboard
        )
        
        appStore = AppStore(environment: env)
        // Ensure no initial tasks are running
        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    func testRestoration_Success_SecretsFound() async {
        // Setup
        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let tokenString = "{{CM_T:\(token)}}"
        let secret = "MySecretValue"
        
        await mockPasteboard.setString(tokenString)
        await mockSession.store(batch: [String(token): secret])
        
        // Mock Regex to perform replacement (naive)
        // Since we are mocking regex, the AppStore logic calls regex.replace
        // We need to ensure our mock replace does something useful or rely on standard string replace for this test if mock is simple
        // In MockServices, we implemented a basic replacement
        
        // Trigger
        appStore.send(.clipboard(.startRestoration))
        
        // Wait for task
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s (includes 0.2s sleep in logic)
        
        // Verify Logic Sequence
        
        // 1. Should have called pasteboard setString with RESTORED content
        // (MockPasteboard records calls. We expect call count >= 2: 1 for restored, 1 for safety restore)
        // But since we can't inspect the history of calls in simple mock, we check if it ENDED safely
        
        // Verify Safety Restore
        let finalContent = await mockPasteboard.string()
        XCTAssertEqual(finalContent, tokenString, "Should have restored the masked content to clipboard")
        
        // Verify Keyboard Paste
        XCTAssertEqual(mockKeyboard.simulatePasteCallCount, 1, "Should have triggered Cmd+V")
        
        // Verify Feedback
        XCTAssertEqual(appStore.hud.isVisible, true)
        XCTAssertEqual(appStore.hud.message, "Restored")
        XCTAssertEqual(appStore.hud.type, .success)
        XCTAssertEqual(mockAudio.playCallCount, 1)
    }
    
    func testRestoration_PartialMiss() async {
        // Setup
        let token1 = "abcdef123456"
        let token2 = "deadbeef0000" // Valid hex but missing from session
        let input = "{{CM_T:\(token1)}} and {{CM_T:\(token2)}}"
        
        await mockPasteboard.setString(input)
        await mockSession.store(batch: [token1: "Secret1"])
        // token2 missing
        
        // Trigger
        appStore.send(.clipboard(.startRestoration))
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify Feedback
        XCTAssertEqual(appStore.hud.message, "Missing Secrets")
        XCTAssertEqual(appStore.hud.type, .error)
        
        // Verify Keyboard Paste occurred (even with partial)
        XCTAssertEqual(mockKeyboard.simulatePasteCallCount, 1)
        
        // Verify Safety Restore
        let finalContent = await mockPasteboard.string()
        XCTAssertEqual(finalContent, input)
    }
    
    func testRestoration_NoTokens() async {
        // Setup
        let input = "Plain text no tokens"
        await mockPasteboard.setString(input)
        
        // Trigger
        appStore.send(.clipboard(.startRestoration))
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify Feedback
        XCTAssertEqual(appStore.hud.message, "No Tokens")
        XCTAssertEqual(appStore.hud.type, .info) // Assuming .info was added
        
        // Verify NO Keyboard Paste
        XCTAssertEqual(mockKeyboard.simulatePasteCallCount, 0, "Should NOT paste if no tokens found")
        
        // Verify No Clipboard Modification (other than initial set)
        XCTAssertEqual(mockPasteboard.setStringCallCount, 1) // Initial setup only
    }
}
