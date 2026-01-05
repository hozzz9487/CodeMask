//
//  CodeMaskApp.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import SwiftUI

@main
struct CodeMaskApp: App {
    // Inject Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 1. Initialize Store (Single Source of Truth)
    @State private var store = AppStore.shared
    
    // 2. Hold the MenuBarManager
    @State private var menuBarManager: MenuBarManager?
    
    var body: some Scene {
        // No WindowGroup for LSUIElement app
        Settings {
            EmptyView() // Placeholder for settings window
        }
        .commands {
            // Remove standard commands if necessary
            CommandGroup(replacing: .newItem) {}
        }
    }
    
    init() {
        // Setup logic can go here or in a delegate
    }
}

// Extension to handle initialization after body is ready is tricky in pure SwiftUI App without WindowGroup.
// A common pattern for Agent apps is to use NSApplicationDelegate adaptor.
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Menu Bar Manager
        menuBarManager = MenuBarManager(store: AppStore.shared)
        
        // Trigger initial permission check
        checkPermissions()
    }
    
    @MainActor
    func checkPermissions() {
        let permissions = PermissionsManager()
        let isAx = permissions.checkAccessibility()
        let isInput = permissions.checkInputMonitoring()
        
        AppStore.shared.send(.security(.permissions(.didCheckStatus(accessibility: isAx, inputMonitoring: isInput))))
        
        // If not trusted, prompt
        if !isAx {
            permissions.promptAccessibility()
        }
    }
}