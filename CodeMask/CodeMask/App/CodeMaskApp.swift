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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = AppStore.shared
    @State private var menuBarManager: MenuBarManager?
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
    
    init() {
        // Setup logic can go here or in a delegate
    }
}

// MARK: - AppDelegate with Smart Permission Handling
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    private var cancellables = Set<AnyCancellable>()
    
    // Track if we've already shown the initial permission alert
    private var hasShownInitialPermissionAlert = false
    
    // Track the last permission state to detect changes
    private var lastPermissionState: (ax: Bool, input: Bool)? = nil
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Menu Bar Manager
        menuBarManager = MenuBarManager(store: AppStore.shared)
        
        // Only show error alert on permission state CHANGES, not every check
        AppStore.shared.permissionChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handlePermissionStateChange()
            }
            .store(in: &cancellables)
        
        // Listen for app becoming active to re-check permissions
        // (user might have returned from System Preferences)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Perform initial permission check on launch
        checkPermissions()
    }
    
    @MainActor
    @objc private func applicationDidBecomeActive() {
        // Re-check permissions when app returns to foreground
        // This allows immediate icon update if user changed settings
        checkPermissions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Permission Management
    
    @MainActor
    private func handlePermissionStateChange() {
        let isAx = AppStore.shared.environment.permissionsManager.checkAccessibility()
        let isInput = AppStore.shared.environment.permissionsManager.checkInputMonitoring()
        let currentState = (isAx, isInput)
        
        // Only show alert if this is the FIRST time permissions failed on launch
        // OR if permissions were revoked after being granted
        let shouldShowAlert = !AppStore.shared.isSafe && (
            !hasShownInitialPermissionAlert ||
            (lastPermissionState?.0 == true && !isAx) ||
            (lastPermissionState?.1 == true && !isInput)
        )
        
        if shouldShowAlert {
            hasShownInitialPermissionAlert = true
            showPermissionAlert()
        }
        
        lastPermissionState = currentState
    }
    
    @MainActor
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = Strings.permissionAlertTitle
        alert.informativeText = Strings.permissionAlertMessage
        alert.alertStyle = .warning  // Changed from critical to warning
        alert.addButton(withTitle: Strings.openSettingsButton)
        alert.addButton(withTitle: "稍後提醒")  // "Remind Later" option
        
        // Bring app to front so alert is visible
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        // If user clicks "Remind Later", just dismiss - don't quit
    }
    
    @MainActor
    func checkPermissions() {
        let permissions = AppStore.shared.environment.permissionsManager
        let isAx = permissions.checkAccessibility()
        let isInput = permissions.checkInputMonitoring()
        
        AppStore.shared.send(.security(.permissions(.didCheckStatus(accessibility: isAx, inputMonitoring: isInput))))
        
        // Only prompt for accessibility if not granted AND we haven't shown alert yet
        // This prevents duplicate prompts
        if !isAx && !hasShownInitialPermissionAlert {
            permissions.promptAccessibility()
        }
    }
}