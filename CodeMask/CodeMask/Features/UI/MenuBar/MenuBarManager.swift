//
//  MenuBarManager.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import AppKit
import SwiftUI
import os
import Combine

@MainActor
final class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private let store: AppStore
    private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "MenuBarManager")
    private var cancellables = Set<AnyCancellable>()
    
    init(store: AppStore) {
        self.store = store
        super.init()
        setupStatusItem()
        startObservation()
    }
    
    private func startObservation() {
        // Observe permission changes and update icon immediately
        store.permissionChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateIcon()
            }
            .store(in: &cancellables)
        
        // Also observe isSafe state changes to ensure icon updates
        // This catches edge cases where permissionChangedPublisher might be missed
        store.isSafePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Default "Safe" icon (SFSymbol)
            // Use system symbols: lock.shield.fill (safe), exclamationmark.shield.fill (danger), etc.
            button.image = NSImage(systemSymbolName: Strings.lockShieldIconDescription, accessibilityDescription: Strings.safeStatusIconDescription)
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
        let statusTitle = store.isSafe ? Strings.statusSafe : Strings.statusUnsafe
        menu.addItem(NSMenuItem(title: "\(Strings.menuItemCodeMaskPrefix) \(statusTitle)", action: nil, keyEquivalent: ""))
        
        if !store.isSafe {
            menu.addItem(NSMenuItem.separator())
            let prefsItem = NSMenuItem(title: Strings.menuItemOpenSystemPreferences, action: #selector(openSystemPreferences), keyEquivalent: ",")
            prefsItem.target = self
            menu.addItem(prefsItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: Strings.menuItemQuit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil) // Show the menu immediately
        // Note: Keep menu assigned; it will be automatically cleared when user clicks elsewhere or menu closes
    }
    
    @objc private func openSystemPreferences() {
        // Open Security & Privacy settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        
        let symbolName = store.isSafe ? "lock.shield.fill" : "exclamationmark.shield.fill"
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