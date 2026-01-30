
import XCTest
import Combine
@testable import CodeMask

final class MaskingLoopTests: XCTestCase {
    
    var mockPasteboard: MockPasteboardService!
    var mockHaptics: MockHapticService!
    var mockAudio: MockAudioService!
    var mockRegexEngine: MockRegexEngine!
    var mockSession: MockSessionActor!
    var store: AppStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        mockPasteboard = MockPasteboardService()
        mockHaptics = MockHapticService()
        mockAudio = MockAudioService()
        mockRegexEngine = MockRegexEngine()
        mockSession = MockSessionActor()
        cancellables = []
        
        // Construct environment with mocks
        let env = AppEnvironment(
            permissionsManager: PermissionsManager(), // Real or mock? verify if needed.
            hotkeyManager: GlobalHotkeyManager(), // We don't trigger via hotkey manager for this test
            session: mockSession,
            pasteboard: mockPasteboard,
            haptics: mockHaptics,
            audio: mockAudio,
            regexEngine: mockRegexEngine
        )
        
        
        store = await MainActor.run {
             AppStore(environment: env)
        }
    }
    
    func testMaskingLoop_Success_SecretsFound() async throws {
        // Given
        await mockPasteboard.setString("My secret is password123")
        
        let token = Clipboard.Token(id: "abc")
        let secrets = [token: "password123"]
        let masked = "My secret is {{CM_T:abc}}"
        
        await mockRegexEngine.setMockResult(Clipboard.MatchResult(maskedString: masked, secrets: secrets))
        
        // When: Trigger masking
        // We assume we send .hotkeys(.didTriggerMasking) which triggers the logic
        await MainActor.run {
            store.send(.hotkeys(.didTriggerMasking))
        }
        
        // Then: Wait for completion
        // We expect .card dispatch .maskingSequenceCompleted
        // Since we can't easily wait for task, we poll for state change or use expectation on a side-effect if possible.
        // Assuming the store will update 'clipboard.lastResult' or 'security.lastActivity' or similar.
        // For now, let's assume we can observe `store.clipboard.lastMaskingResult`
        
        // Since the AppStore doesn't have `clipboard` yet, this will fail compilation.
        // We need to implement this state in the Green phase.
        
        try await waitForCondition(timeout: 2.0) {
            await MainActor.run {
                return store.hud.isVisible
            }
        }
        
        // Verify Mocks
        let written = await mockPasteboard.lastWrittenString
        XCTAssertEqual(written, masked)
        
        let stored = await mockSession.getStoredContent(for: "abc")
        XCTAssertEqual(stored, "password123")
        
        let hapticCount = mockHaptics.playCallCount
        XCTAssertEqual(hapticCount, 1) // Success haptic
        
        let audioCount = mockAudio.playCallCount
        XCTAssertEqual(audioCount, 1) // Success sound
    }
    
    func testMaskingLoop_NoSecrets() async throws {
        // Given
        await mockPasteboard.setString("Just plain text")
        await mockRegexEngine.setMockResult(Clipboard.MatchResult(maskedString: "Just plain text", secrets: [:]))
        
        // When
        await MainActor.run {
            store.send(.hotkeys(.didTriggerMasking))
        }
        
        // Wait... logic similar to above
        // Assert: Pasteboard NOT written to (avoid churn)
    }
    
    func testMaskingLoop_RaceCondition() async throws {
        // Given
        await mockRegexEngine.setDelay(50_000_000) // 50ms
        
        // Trigger A
        await mockPasteboard.setString("Content A")
        let tokenA = Clipboard.Token(id: "A")
        await mockRegexEngine.setMockResult(Clipboard.MatchResult(maskedString: "Masked A", secrets: [tokenA: "Secret A"]))
        
        await MainActor.run {
            store.send(.hotkeys(.didTriggerMasking))
        }
        
        // Wait 10ms (Wait less than delay)
        try await Task.sleep(nanoseconds: 10_000_000)
        
        // Trigger B
        await mockPasteboard.setString("Content B")
        let tokenB = Clipboard.Token(id: "B")
        await mockRegexEngine.setMockResult(Clipboard.MatchResult(maskedString: "Masked B", secrets: [tokenB: "Secret B"]))
        
        await MainActor.run {
            store.send(.hotkeys(.didTriggerMasking))
        }
        
        // Wait for completion (Wait longer than delay)
        try await waitForCondition(timeout: 2.0) {
            await MainActor.run { return store.hud.isVisible }
        }
        
        // Verify
        // Only B should be written
        let written = await mockPasteboard.lastWrittenString
        XCTAssertEqual(written, "Masked B")
        
        // Should NOT contain A's secret
        let storedA = await mockSession.getStoredContent(for: "A")
        XCTAssertNil(storedA, "Task A should have been cancelled and not stored secrets")
        
        let storedB = await mockSession.getStoredContent(for: "B")
        XCTAssertEqual(storedB, "Secret B")
    }
    
    // Helper
    func waitForCondition(timeout: TimeInterval, condition: () async -> Bool) async throws {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await condition() { return }
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        // XCTFail("Timeout") // Don't fail here, let assertions fail
    }
}
