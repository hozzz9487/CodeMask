//
//  MenuBarManager.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import AppKit
import SwiftUI
import os

@MainActor
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private let store: AppStore
    private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "MenuBarManager")
    
    init(store: AppStore) {
        self.store = store
        super.init()
        setupStatusItem()
        startObservation()
    }
    
    private func startObservation() {
        // Continuous observation of store.isSafe
        withObservationTracking {
            _ = store.isSafe
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateIcon()
                // Re-register observation for next change
                self.startObservation()
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Default "Safe" icon (SFSymbol)
            // Use system symbols: lock.shield (safe), lock.shield.warning (danger), etc.
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "CodeMask Safe")
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        updateIcon()
    }
    
    @objc private func menuBarClicked() {
        // Future: Toggle popover or show menu
        logger.debug("Menu bar clicked")
        
        // Simple menu for scaffolding
        let menu = NSMenu()
        let statusTitle = store.isSafe ? "Safe" : "Setup Required"
        menu.addItem(NSMenuItem(title: "CodeMask: \(statusTitle)", action: nil, keyEquivalent: ""))
        
        if !store.isSafe {
            menu.addItem(NSMenuItem.separator())
            let prefsItem = NSMenuItem(title: "Open System Preferences", action: #selector(openSystemPreferences), keyEquivalent: ",")
            prefsItem.target = self
            menu.addItem(prefsItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Show the menu immediately
        statusItem.menu = nil // Clear it so subsequent clicks can re-evaluate or do custom logic
    }
    
    @objc private func openSystemPreferences() {
        // Open Security & Privacy settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        
        let symbolName = store.isSafe ? "lock.shield.fill" : "lock.shield.warning"
        // Use Warning symbol for unsafe state
        
        let config = NSImage.SymbolConfiguration(paletteColors: [store.isSafe ? .systemBlue : .systemOrange])
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            button.image = image
        } else {
            // Fallback for missing symbol and log failure
            logger.error("Failed to load symbol: \(symbolName)")
            button.title = "CM"
        }
    }
}