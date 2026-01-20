import XCTest
@testable import CodeMask

final class RegexEngineTests: XCTestCase {
    func testInitialization() async {
        let engine = Clipboard.RegexEngine()
        let result = await engine.mask("test")
        XCTAssertEqual(result.maskedString, "test")
        XCTAssertTrue(result.secrets.isEmpty)
    }

    func testDefaultRules() {
        let defaults = Clipboard.Rule.defaults
        XCTAssertFalse(defaults.isEmpty)
    }

    func testBasicMasking() async {
        let engine = Clipboard.RegexEngine()
        await engine.updateRules(Clipboard.Rule.defaults)
        
        let sensitive = "Contact me at test@example.com for details."
        let result = await engine.mask(sensitive)
        
        XCTAssertNotEqual(result.maskedString, sensitive)
        XCTAssertTrue(result.maskedString.contains("{{CM_T:"))
        XCTAssertEqual(result.secrets.count, 1)
        XCTAssertEqual(result.secrets.first?.value, "test@example.com")
    }

    func testOverlapLogic() async {
        let engine = Clipboard.RegexEngine()
        
        // Case A: Longest Match First
        // Rule 1: Matches "https://a.com"
        // Rule 2: Matches "a.com"
        let rule1 = Clipboard.Rule(pattern: "https://a\\.com", isEnabled: true)
        let rule2 = Clipboard.Rule(pattern: "a\\.com", isEnabled: true)
        
        await engine.updateRules([rule1, rule2])
        let inputA = "Visit https://a.com now"
        let resultA = await engine.mask(inputA)
        
        // Should mask the full URL, not just the domain part twice or something weird
        // Since "https://a.com" is longer (13 chars) than "a.com" (5 chars), it should win.
        XCTAssertEqual(resultA.secrets.count, 1)
        XCTAssertEqual(resultA.secrets.values.first, "https://a.com")
        
        // Case B: Left-most First for Equal Length (roughly) or Overlapping
        // Input: "ABC"
        // Rule 3: "AB"
        // Rule 4: "BC"
        let rule3 = Clipboard.Rule(pattern: "AB", isEnabled: true)
        let rule4 = Clipboard.Rule(pattern: "BC", isEnabled: true)
        
        await engine.updateRules([rule3, rule4])
        let inputB = "ABC"
        let resultB = await engine.mask(inputB)
        
        // "AB" starts at 0. "BC" starts at 1.
        // Both length 2.
        // Primary sort: Length (Tie)
        // Secondary sort: Position (0 vs 1). 0 wins.
        // "AB" is selected. "BC" overlaps "AB" (B is shared), so "BC" should be discarded.
        
        XCTAssertEqual(resultB.secrets.count, 1)
        XCTAssertTrue(resultB.secrets.values.contains("AB"))
        XCTAssertFalse(resultB.secrets.values.contains("BC"))
        
        // Verify masked string has "C" remaining
        // "AB" -> {{TOKEN}}
        // Result: "{{TOKEN}}C"
        XCTAssertTrue(resultB.maskedString.hasSuffix("C"))
    }

    func testPerformance() async {
        let engine = Clipboard.RegexEngine()
        await engine.updateRules(Clipboard.Rule.defaults)
        
        // Approx 70KB of text
        let text = String(repeating: "Here is an email: test@example.com and a url https://example.com/page ", count: 1000)
        
        let start = Date()
        let _ = await engine.mask(text)
        let duration = Date().timeIntervalSince(start)
        
        // Allow slightly more buffer for CI/simulated env, but aim for < 0.1s
        XCTAssertLessThan(duration, 0.5, "Masking took too long: \(duration)s")
    }
}
