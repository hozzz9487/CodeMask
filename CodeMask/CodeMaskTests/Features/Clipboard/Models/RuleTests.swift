import XCTest
@testable import CodeMask

final class RuleTests: XCTestCase {
    
    func testRuleConformanceAndProperties() throws {
        // This test validates that Clipboard.Rule conforms to Codable, Identifiable, Sendable
        // and has the required properties including the new 'name' field.
        
        let id = UUID()
        let name = "Test Rule"
        let pattern = "^test$"
        let isEnabled = true
        
        // This init is expected to fail compilation until implemented
        let rule = Clipboard.Rule(
            id: id,
            name: name,
            pattern: pattern,
            isEnabled: isEnabled
        )
        
        // Verify Codable conformance
        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)
        
        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(Clipboard.Rule.self, from: data)
        
        XCTAssertEqual(decodedRule.id, id)
        XCTAssertEqual(decodedRule.name, name)
        XCTAssertEqual(decodedRule.pattern, pattern)
        XCTAssertEqual(decodedRule.isEnabled, isEnabled)
    }
    
    func testDefaultRulesHaveNames() {
        // Verify that default rules have be updated to include names
        let defaults = Clipboard.Rule.defaults
        
        for rule in defaults {
            XCTAssertFalse(rule.name.isEmpty, "Default rules must have non-empty names")
        }
    }
    func testMobilePackJSONIsValid() throws {
        let jsonURL = TestUtils.mobilePackURL
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path), "MobilePack.json should exist at \(jsonURL.path)")
        
        // Load and decode
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        let rules = try decoder.decode([Clipboard.Rule].self, from: data)
        
        // Validation assertions
        XCTAssertEqual(rules.count, 4)
        XCTAssertEqual(rules[0].name, "iOS Bundle ID")
        XCTAssertEqual(rules[1].name, "Apple Team ID")
    }
}
