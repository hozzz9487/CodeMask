//
//  CodeMaskApp.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import SwiftUI
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    private var permissionCheckTimer: Timer?
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Menu Bar Manager
        menuBarManager = MenuBarManager(store: AppStore.shared)
        
        // Start observing state for errors via Combine
        AppStore.shared.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        // Trigger initial permission check
        checkPermissions()
        
        // Start background permission monitor to detect external permission revocation
        // Check every 5 seconds to catch permission changes made in System Preferences
        startPermissionMonitor()
    }
    
    @MainActor
    private func startPermissionMonitor() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
    }
    
    @MainActor
    private func handleError(_ error: AppError?) {
        guard let error = error else { return }
        
        if error == .permissionsCheckFailed {
            let alert = NSAlert()
            alert.messageText = Strings.permissionAlertTitle
            alert.informativeText = Strings.permissionAlertMessage
            alert.alertStyle = .critical
            alert.addButton(withTitle: Strings.openSettingsButton)
            alert.addButton(withTitle: Strings.quitButton)
            
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