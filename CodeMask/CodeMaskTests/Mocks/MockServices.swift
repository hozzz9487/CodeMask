
import Foundation
import XCTest
@testable import CodeMask

// MARK: - Mock Pasteboard

final class MockPasteboardService: PasteboardServiceProtocol, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _mockString: String?
    private var _setStringCallCount = 0
    private var _lastWrittenString: String?
    
    var mockString: String? {
        get { lock.withLock { _mockString } }
        set { lock.withLock { _mockString = newValue } }
    }
    
    var setStringCallCount: Int {
        lock.withLock { _setStringCallCount }
    }
    
    var lastWrittenString: String? {
        lock.withLock { _lastWrittenString }
    }
    
    func string() async -> String? {
        // Retrieve safely
        lock.withLock { _mockString }
    }
    
    func setString(_ content: String) async {
        lock.withLock {
            _setStringCallCount += 1
            _lastWrittenString = content
            _mockString = content // Simulate pasteboard update
        }
    }
}

// MARK: - Mock Haptics

final class MockHapticService: HapticServiceProtocol, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _playCallCount = 0
    private var _lastFeedback: HapticFeedbackType?
    
    var playCallCount: Int { lock.withLock { _playCallCount } }
    var lastFeedback: HapticFeedbackType? { lock.withLock { _lastFeedback } }
    
    func prepare() {
        // No-op
    }
    
    func play(_ feedback: HapticFeedbackType) {
        lock.withLock {
            _playCallCount += 1
            _lastFeedback = feedback
        }
    }
}

// MARK: - Mock Audio

final class MockAudioService: AudioServiceProtocol, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _playCallCount = 0
    private var _lastSound: SystemSound?
    
    var playCallCount: Int { lock.withLock { _playCallCount } }
    var lastSound: SystemSound? { lock.withLock { _lastSound } }
    
    func prepare(sound: SystemSound) {
        // No-op
    }
    
    func playSystemSound(_ sound: SystemSound) {
        lock.withLock {
            _playCallCount += 1
            _lastSound = sound
        }
    }
}

// MARK: - Mock Regex Engine

actor MockRegexEngine: Clipboard.RegexEngineProtocol {
    
    var mockResult: Clipboard.MatchResult?
    var maskCallCount = 0
    var delayNanoseconds: UInt64?
    
    // We need to match the type alias match result
    // Assuming type aliases are visible. Matches implementation: MatchResult
    
    func updateRules(_ rules: [Clipboard.Rule]) -> Clipboard.RuleUpdateReport {
        return Clipboard.RuleUpdateReport(validCount: 0, invalidCount: 0, invalidRules: [])
    }
    
    func mask(_ content: String) async -> Clipboard.MatchResult {
        if let delay = delayNanoseconds {
            try? await Task.sleep(nanoseconds: delay)
        }
        maskCallCount += 1
        if let result = mockResult {
            return result
        }
        // Default empty result
        return Clipboard.MatchResult(maskedString: content, secrets: [:])
    }
    
    func scanForTokenIDs(_ content: String) async -> [String] {
        // Simple manual extraction for mock
        // Assumes format {{CM_T:id}}
        // Regex: {{CM_T:([a-f0-9]{12})}}
        
        let pattern = "\\{\\{CM_T:([a-f0-9]{12})\\}\\}"
        guard let regex = try? Regex(pattern) else { return [] }
        
        let matches = content.matches(of: regex)
        let ids = matches.compactMap { match -> String? in
            if match.output.count > 1 {
                let substring = match.output[1].substring
                return String(substring ?? "")
            }
            return nil
        }
        return Array(Set(ids))
    }
    
    func replace(content: String, mapping: [String: String?]) async -> String {
        // Simple mock implementation that doesn't actually parse regex but serves testing needs if needed.
        // Or we can just return a pre-set value.
        // For better testing, let's do a naive replace if possible, or just return content + " [Restored]"
        
        // Naive mock replacement for known patterns
        var result = content
        for (id, secretOpt) in mapping {
            let token = "{{CM_T:\(id)}}"
            if let secret = secretOpt {
                result = result.replacingOccurrences(of: token, with: secret)
            } else {
                result = result.replacingOccurrences(of: token, with: ">>MISSING_SECRET<<")
            }
        }
        return result
    }
    
    func setDelay(_ nanos: UInt64?) {
        self.delayNanoseconds = nanos
    }
    
    func setMockResult(_ result: Clipboard.MatchResult) {
        self.mockResult = result
    }
}

// MARK: - Mock Session Actor

actor MockSessionActor: SessionStorageProtocol {
    
    private var storage: [String: String] = [:]
    
    func store(content: String) -> UUID {
        let id = UUID()
        storage[id.uuidString] = content
        return id
    }
    
    func store(batch: [String: String]) {
        for (key, value) in batch {
            storage[key] = value
        }
    }
    
    func retrieve(id: UUID) -> String? {
        return storage[id.uuidString]
    }
    
    func resolve(tokens: [String]) -> [String: String?] {
        var results: [String: String?] = [:]
        for token in tokens {
            results[token] = storage[token]
        }
        return results
    }
    
    func clear() {
        storage.removeAll()
    }
    
    // Test helpers
    func getStoredContent(for id: String) -> String? {
        return storage[id]
    }
    
    func count() -> Int {
        return storage.count
    }
}

// MARK: - Mock Keyboard

final class MockKeyboardService: KeyboardServiceProtocol, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _simulateCopyCallCount = 0
    private var _simulatePasteCallCount = 0
    
    var simulateCopyCallCount: Int { lock.withLock { _simulateCopyCallCount } }
    var simulatePasteCallCount: Int { lock.withLock { _simulatePasteCallCount } }
    
    func simulateCopy() async {
        lock.withLock { _simulateCopyCallCount += 1 }
    }
    
    func simulatePaste() async {
        lock.withLock { _simulatePasteCallCount += 1 }
    }
}
