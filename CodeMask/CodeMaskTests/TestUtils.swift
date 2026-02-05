import Foundation

final class TestUtils {
    static var projectRoot: URL {
        // More robust root finding: Move up from this file until we find the Package.swift or slightly more reliable anchor?
        // For now, we stick to the relative path cleaning but centralize it here.
        // File: CodeMask/CodeMaskTests/TestUtils.swift
        let currentFileURL = URL(fileURLWithPath: #file)
        return currentFileURL
            .deletingLastPathComponent() // CodeMaskTests
            .deletingLastPathComponent() // CodeMask
    }
    
    static var mobilePackURL: URL {
        return projectRoot
            .appendingPathComponent("CodeMask")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Presets")
            .appendingPathComponent("MobilePack.json")
    }
}
