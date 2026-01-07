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
        // Epic 3: Settings Window will go here
        Settings {
            EmptyView()
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
        
        // Start observing state for errors
        startObservation()
        
        // Trigger initial permission check
        checkPermissions()
    }
    
    @MainActor
    private func startObservation() {
        withObservationTracking {
            _ = AppStore.shared.security.lastError
        } onChange: {
            Task { @MainActor [weak self] in
                self?.handleError(AppStore.shared.security.lastError)
                self?.startObservation()
            }
        }
    }
    
    @MainActor
    private func handleError(_ error: AppError?) {
        guard let error = error else { return }
        
        if error == .permissionsCheckFailed {
            let alert = NSAlert()
            alert.messageText = "Permissions Required"
            alert.informativeText = "CodeMask needs Accessibility and Input Monitoring permissions to function. Please grant them in System Settings."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Quit")
            
            // Bring app to front so alert is visible
            NSApp.activate(ignoringOtherApps: true)
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open Settings
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            } else {
                NSApplication.shared.terminate(nil)
            }
            
            // Clear error after handling so we can detect future errors
            AppStore.shared.send(.security(.didClearError))
        }
    }
    
    @MainActor
    func checkPermissions() {
        let permissions = AppStore.shared.environment.permissionsManager
        let isAx = permissions.checkAccessibility()
        let isInput = permissions.checkInputMonitoring()
        
        AppStore.shared.send(.security(.permissions(.didCheckStatus(accessibility: isAx, inputMonitoring: isInput))))
        
        // If not trusted, prompt and signal error state
        if !isAx || !isInput {
            AppStore.shared.send(.security(.didEncounterError(.permissionsCheckFailed)))
            if !isAx {
                permissions.promptAccessibility()
            }
        }
    }
}
