//
//  MenuBarManager.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import AppKit
import SwiftUI

@MainActor
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private let store: AppStore
    
    init(store: AppStore) {
        self.store = store
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Default "Safe" icon (SFSymbol)
            // Use system symbols: lock.shield (safe), lock.shield.warning (danger), etc.
            // For MVP scaffolding, we just set a static image initially.
            // In a real app, this would observe Store state.
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "CodeMask Safe")
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        updateIcon()
    }
    
    @objc private func menuBarClicked() {
        // Future: Toggle popover or show menu
        print("Menu bar clicked")
        
        // Simple menu for scaffolding
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "CodeMask: " + (store.isSafe ? "Safe" : "Setup Required"), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Show the menu immediately
        statusItem.menu = nil // Clear it so subsequent clicks can re-evaluate or do custom logic
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        
        let symbolName = store.isSafe ? "lock.shield.fill" : "lock.shield"
        let config = NSImage.SymbolConfiguration(paletteColors: [store.isSafe ? .systemBlue : .systemGray])
        
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
    }
}
