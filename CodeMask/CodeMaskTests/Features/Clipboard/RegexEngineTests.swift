import XCTest
@testable import CodeMask

final class RegexEngineTests: XCTestCase {
    var sut: Clipboard.RegexEngine!

    override func setUp() async throws {
        sut = Clipboard.RegexEngine()
    }

    func testUpdateRulesReturnsStatus() async {
        let validRule = Clipboard.Rule(id: UUID(), name: "Valid", pattern: "\\d+", isEnabled: true)
        let invalidRule = Clipboard.Rule(id: UUID(), name: "Invalid", pattern: "[", isEnabled: true) // Invalid regex

        let report = await sut.updateRules([validRule, invalidRule])

        XCTAssertEqual(report.validCount, 1)
        XCTAssertEqual(report.invalidCount, 1)
        XCTAssertTrue(report.invalidRules.contains(invalidRule.id))
    }

    func testBasicMasking() async {
        let rule = Clipboard.Rule(name: "Secret", pattern: "secret", isEnabled: true)
        _ = await sut.updateRules([rule])

        let input = "This is a secret message"
        let result = await sut.mask(input)

        XCTAssertFalse(result.maskedString.contains("secret"))
        XCTAssertTrue(result.maskedString.contains("{{CM_T:"))
        // Token should be 12 chars (from prefix(12))
        XCTAssertEqual(result.secrets.keys.first?.id.count, 12)
        XCTAssertEqual(result.secrets.count, 1)
        XCTAssertEqual(result.secrets.values.first, "secret")
    }

    func testLabelPreservation() async {
        // Test the lookbehind rule
        let rules = Clipboard.Rule.defaults
        _ = await sut.updateRules(rules)
        
        let input = "My api_key: sk-1234567890abcdef12345"
        let result = await sut.mask(input)
        
        XCTAssertTrue(result.maskedString.contains("api_key: {{CM_T:"), "Should preserve the label 'api_key: '")
        XCTAssertFalse(result.maskedString.contains("sk-1234567890"), "Should mask the value")
    }

    func testOverlapPriority_LongestWins() async {
        // "https://a.com" vs "a.com"
        let ruleLong = Clipboard.Rule(name: "Long", pattern: "https://a\\.com", isEnabled: true)
        let ruleShort = Clipboard.Rule(name: "Short", pattern: "a\\.com", isEnabled: true)
        
        _ = await sut.updateRules([ruleLong, ruleShort])
        
        let input = "Visit https://a.com now"
        let result = await sut.mask(input)
        
        // Should have 1 token covering the longer match
        XCTAssertEqual(result.secrets.count, 1)
        XCTAssertEqual(result.secrets.values.first, "https://a.com")
    }
    
    func testOverlapPriority_LeftMostWins() async {
        // "ABC" with rules "AB" and "BC" -> "AB" wins because it starts earlier
        let ruleAB = Clipboard.Rule(name: "AB", pattern: "AB", isEnabled: true)
        let ruleBC = Clipboard.Rule(name: "BC", pattern: "BC", isEnabled: true)
        
        _ = await sut.updateRules([ruleAB, ruleBC])
        
        let input = "ABC"
        let result = await sut.mask(input)
        
        XCTAssertEqual(result.secrets.count, 1)
        XCTAssertEqual(result.secrets.first?.value, "AB")
    }

    func testPerformanceStrict() async {
        // Generate 50 rules
        let rules = (0..<50).map {
            Clipboard.Rule(name: "PerfRule\($0)", pattern: "testpattern\($0)", isEnabled: true)
        }
        _ = await sut.updateRules(rules)
        
        // Generate ~50KB text
        // "testpattern10 " is 14 chars. 4000 repeats ~ 56KB.
        let text = String(repeating: "testpattern10 ", count: 4000)
        
        let start = Date()
        _ = await sut.mask(text)
        let duration = Date().timeIntervalSince(start)
        
        // AC says < 100ms (0.1s)
        XCTAssertLessThan(duration, 0.1, "Masking took too long: \(duration)s")
    }
    
    func testReplace() async {
        let input = "Here is {{CM_T:1234567890ab}} and {{CM_T:deadbeef0000}}"
        let mapping: [String: String?] = [
            "1234567890ab": "mySecret",
            "deadbeef0000": nil
        ]
        
        let result = await sut.replace(content: input, mapping: mapping)
        
        XCTAssertTrue(result.contains("Here is mySecret"))
        XCTAssertTrue(result.contains("and >>MISSING_SECRET<<"))
        XCTAssertFalse(result.contains("{{CM_T:"))
    }
}