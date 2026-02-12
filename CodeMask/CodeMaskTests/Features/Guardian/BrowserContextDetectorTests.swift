//
//  BrowserContextDetectorTests.swift
//  CodeMaskTests
//
//  Created by Edison on 2026/2/12.
//

import XCTest
@testable import CodeMask

@MainActor
final class BrowserContextDetectorTests: XCTestCase {
    
    var detector: BrowserContextDetector!
    
    override func setUp() {
        super.setUp()
        detector = BrowserContextDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    func testBrowserBundleID_YieldsDidActivate() async {
        // Given
        let browserBundleID = "com.apple.Safari"
        
        // When
        detector.checkBundleID(browserBundleID)
        
        // Then
        var iterator = detector.events.makeAsyncIterator()
        let event = await iterator.next()
        
        XCTAssertEqual(event, .didActivateBrowserApp(bundleID: browserBundleID))
    }
    
    func testNonBrowserBundleID_YieldsDidDeactivate() async {
        // Given
        let nonBrowserBundleID = "com.apple.finder"
        
        // When
        detector.checkBundleID(nonBrowserBundleID)
        
        // Then
        var iterator = detector.events.makeAsyncIterator()
        let event = await iterator.next()
        
        XCTAssertEqual(event, .didDeactivateBrowserApp)
    }
    
    func testRapidSwitching() async {
        // Given
        let sequence = [
            "com.apple.Safari",
            "com.apple.finder",
            "com.google.Chrome"
        ]
        
        // When
        for id in sequence {
            detector.checkBundleID(id)
        }
        
        // Then
        var iterator = detector.events.makeAsyncIterator()
        
        let event1 = await iterator.next()
        XCTAssertEqual(event1, .didActivateBrowserApp(bundleID: "com.apple.Safari"))
        
        let event2 = await iterator.next()
        XCTAssertEqual(event2, .didDeactivateBrowserApp)
        
        let event3 = await iterator.next()
        XCTAssertEqual(event3, .didActivateBrowserApp(bundleID: "com.google.Chrome"))
    }
}
