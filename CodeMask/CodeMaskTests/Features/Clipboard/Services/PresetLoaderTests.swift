import XCTest
@testable import CodeMask

final class PresetLoaderTests: XCTestCase {
    
    func testLoadMobilePresets_FromDisk() throws {
        // Locate the JSON file relative to this test file
        // Path: CodeMaskTests/Features/Clipboard/Services/PresetLoaderTests.swift
        let currentFileURL = URL(fileURLWithPath: #file)
        let projectRoot = currentFileURL
            .deletingLastPathComponent() // Services
            .deletingLastPathComponent() // Clipboard
            .deletingLastPathComponent() // Features
            .deletingLastPathComponent() // CodeMaskTests
            .deletingLastPathComponent() // CodeMask (Project Root)
        
        let jsonURL = projectRoot
            .appendingPathComponent("CodeMask")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Presets")
            .appendingPathComponent("MobilePack.json")
        
        // Verify file exists first
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
