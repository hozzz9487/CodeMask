//
//  MenuBarManagerTests.swift
//  CodeMaskTests
//

import XCTest
import AppKit
@testable import CodeMask

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    var manager: MenuBarManager!
    var appStore: AppStore!
    
    override func setUp() {
        super.setUp()
        // 使用預設環境或手動注入 Mock
        appStore = AppStore(environment: AppEnvironment())
        manager = MenuBarManager(appStore: appStore)
    }
    
    override func tearDown() {
        manager = nil
        appStore = nil
        super.tearDown()
    }
    
    func testIconConfiguration_Idle_ReturnsCorrectValues() {
        let (symbol, color, label) = manager.iconConfiguration(for: .idle)
        XCTAssertEqual(symbol, "shield")
        // 驗證已改用 secondaryLabelColor 以提升失焦螢幕清晰度
        XCTAssertEqual(color, .secondaryLabelColor)
        XCTAssertTrue(label.contains("Safe"))
    }
    
    func testIconConfiguration_Secured_ReturnsCorrectValues() {
        let (symbol, color, label) = manager.iconConfiguration(for: .secured)
        XCTAssertEqual(symbol, "lock.shield.fill")
        XCTAssertEqual(color, .systemBlue)
        XCTAssertTrue(label.contains("Secured"))
    }
    
    func testIconConfiguration_Warning_ReturnsCorrectValues() {
        let (symbol, color, label) = manager.iconConfiguration(for: .warning)
        XCTAssertEqual(symbol, "exclamationmark.shield.fill")
        XCTAssertEqual(color, .systemRed)
        XCTAssertTrue(label.contains("Warning"))
    }
    
    func testIconConfiguration_Unknown_ReturnsCorrectValues() {
        let (symbol, color, label) = manager.iconConfiguration(for: .unknown)
        XCTAssertEqual(symbol, "shield.slash") // 驗證已修正為正確存在的 SF Symbol
        XCTAssertEqual(color, .secondaryLabelColor) // 驗證優化顏色
        XCTAssertTrue(label.contains("Unknown"))
    }
    
    func testUpdateIcon_GreyStates_ShouldUseTemplate() {
        // Given
        let status: Session.SecurityStatus = .idle
        
        // When
        manager.updateIcon(for: status)
        
        // Then
        let button = manager.statusItem?.button
        XCTAssertNotNil(button, "Status item button should not be nil")
        
        if let image = button?.image {
            XCTAssertTrue(image.isTemplate, "灰色狀態應使用 Template 讓 macOS 自動優化對比度")
        } else {
            XCTFail("Button image should not be nil for grey states")
        }
    }
    
    func testUpdateIcon_ColoredStates_ShouldNotUseTemplate() {
        // Given
        let status: Session.SecurityStatus = .secured
        
        // When
        manager.updateIcon(for: status)
        
        // Then
        let button = manager.statusItem?.button
        XCTAssertNotNil(button, "Status item button should not be nil")
        
        if let image = button?.image {
            // Note: Images with palette configurations usually shouldn't be templates 
            // to preserve the custom colors.
            XCTAssertFalse(image.isTemplate, "彩色狀態不應使用 Template 以保持自定義色調")
        } else {
            XCTFail("Button image should not be nil for colored states")
        }
    }
}

// Helper to access private statusItem in tests
extension MenuBarManager {
    var statusItem: NSStatusItem? {
        // 使用 Mirror 或是 KVC 來讀取私有成份
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "statusItem", let item = child.value as? NSStatusItem {
                return item
            }
        }
        return nil
    }
}
