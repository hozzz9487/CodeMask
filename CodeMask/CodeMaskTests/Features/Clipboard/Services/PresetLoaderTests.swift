import XCTest
@testable import CodeMask

final class PresetLoaderTests: XCTestCase {
    
    func testLoadMobilePresets_FromDisk() throws {
        // Verify file exists
        let jsonURL = TestUtils.mobilePackURL
        
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            XCTFail("MobilePack.json not found at \(jsonURL.path)")
            return
        }
        
        // Test Logic
        let rules = try Clipboard.PresetLoader.loadRules(at: jsonURL)
        
        XCTAssertEqual(rules.count, 4)
        XCTAssertEqual(rules.first?.name, "iOS Bundle ID")
        XCTAssertEqual(rules.last?.name, "Google/Firebase API Key")
    }
}
