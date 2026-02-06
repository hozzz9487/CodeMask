//
//  MenuBarManager.swift
//  CodeMask
//
//  Created by BMad Dev Agent on 2026/02/05.
//

import AppKit
import Combine
import SwiftUI

/// Manages the application's menu bar status item.
/// Reflects the current security status via icon and color.
@MainActor
final class MenuBarManager: NSObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()
    private let appStore: AppStore
    
    // Debounce for updates
    private var currentStatus: Session.SecurityStatus = .idle
    
    // MARK: - Initialization
    
    init(appStore: AppStore) {
        self.appStore = appStore
        super.init()
        setupStatusItem()
        setupSubscriptions()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageLeft
        
        // Initial state
        updateIcon(for: .idle)
    }
    
    private func setupSubscriptions() {
        startObservation()
    }
    
    private func startObservation() {
        withObservationTracking {
            // Access properties to track
            _ = appStore.session.securityStatus
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.handleStateChange()
                // Re-register observation
                self.startObservation()
            }
        }
    }
    
    private func handleStateChange() {
        let newStatus = appStore.session.securityStatus
        
        // Simple debounce/guard
        guard newStatus != currentStatus else { return }
        currentStatus = newStatus
        
        updateIcon(for: newStatus)
        
        if newStatus == .warning {
            triggerWarningFlash()
        }
    }
    
    // MARK: - UI Updates
    
    func updateIcon(for status: Session.SecurityStatus) {
        guard let button = statusItem.button else { return }
        
        let (symbolName, color, label) = iconConfiguration(for: status)
        
        // Create configuration
        let config = NSImage.SymbolConfiguration(paletteColors: [color])
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label) {
            button.image = image.withSymbolConfiguration(config)
        }
        
        button.setAccessibilityLabel(label)
        button.toolTip = label
    }
    
    func iconConfiguration(for status: Session.SecurityStatus) -> (String, NSColor, String) {
        switch status {
        case .idle:
            return ("shield", .systemGray, "CodeMask: Safe")
        case .secured:
            return ("lock.shield.fill", .systemBlue, "CodeMask: Secured")
        case .warning:
            return ("exclamationmark.shield.fill", .systemRed, "CodeMask: Warning")
        case .unknown:
            return ("questionmark.shield", .systemGray, "CodeMask: Status Unknown")
        }
    }
    
    private func triggerWarningFlash() {
        // Simple 3-pulse flash
        Task {
            for _ in 0..<3 {
                // Dim/Hide
                statusItem.button?.alphaValue = 0.3
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                
                // Restore
                statusItem.button?.alphaValue = 1.0
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
            }
        }
    }
}
