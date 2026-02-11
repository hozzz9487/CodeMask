//
//  CodeMaskApp.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import SwiftUI
import Combine
import os

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
    var hudManager: HUDManager?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "AppDelegate")
    
    // Track if we've already shown the initial permission alert
    private var hasShownInitialPermissionAlert = false
    
    // Track the last permission state to detect changes
    private var lastPermissionState: (ax: Bool, input: Bool)? = nil
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Menu Bar Manager
        menuBarManager = MenuBarManager(appStore: AppStore.shared)
        
        // Initialize HUD Manager
        hudManager = HUDManager(store: AppStore.shared)
        
        // Skip logic that triggers system permission prompts or hardware registration in unit tests
        if AppEnvironment.isRunningUnitTests {
            logger.info("Unit test environment detected. Minimal initialization performed.")
            return
        }

        // Register Global Hotkeys
        AppStore.shared.environment.hotkeyManager.registerHotkeys()
        
        // Only show error alert on permission state CHANGES, not every check
        AppStore.shared.permissionChangedPublisher
            .sink { [weak self] in
                self?.handlePermissionStateChange()
            }
            .store(in: &cancellables)
        
        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Listen for workspace app activation (when user returns from System Settings)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivateApplication),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Listen for System Settings window changes (when user exits Settings app)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidHideApplication),
            name: NSWorkspace.didHideApplicationNotification,
            object: nil
        )
        
        // Perform initial permission check on launch
        checkPermissions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Unregister hotkeys on app termination
        AppStore.shared.environment.hotkeyManager.unregisterHotkeys()
    }
    
    @MainActor
    @objc private func applicationDidBecomeActive() {
        // Re-check permissions when app returns to foreground
        checkPermissions()
    }
    
    @MainActor
    @objc private func workspaceDidActivateApplication(_ notification: Notification) {
        // Check permissions whenever any app is activated
        // This catches the moment user leaves System Settings or returns to another app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.checkPermissions()
        }
    }
    
    @MainActor
    @objc private func workspaceDidHideApplication(_ notification: Notification) {
        // When System Settings is hidden (user closes or minimizes it), check permissions
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let bundleId = app.bundleIdentifier ?? ""
        if bundleId.contains("systempreferences") || bundleId.contains("system.settings") {
            // User just closed System Settings - check permissions immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.checkPermissions()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @MainActor
    private func handlePermissionStateChange() {
        let isAx = AppStore.shared.environment.permissionsManager.checkAccessibility()
        let isInput = AppStore.shared.environment.permissionsManager.checkInputMonitoring()
        let currentState = (isAx, isInput)
        
        // Detect if permissions changed from granted to revoked
        let axRevoked = lastPermissionState?.0 == true && !isAx
        let inputRevoked = lastPermissionState?.1 == true && !isInput
        
        // Handle Input Monitoring revoked - special case requiring app restart
        if inputRevoked {
            showRestartAlert()
        }
        // Handle Accessibility revoked or initial permission failure
        else if !AppStore.shared.isSafe && ((!hasShownInitialPermissionAlert && lastPermissionState == nil) || axRevoked) {
            hasShownInitialPermissionAlert = true
            showPermissionAlert()
        }
        
        lastPermissionState = currentState
    }
    
    @MainActor
    private func showPermissionAlert() {
        if AppStore.shared.environment.shouldSuppressAlerts {
            logger.info("Suppressed Permission Alert (Testing Mode)")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = Strings.permissionAlertTitle
        alert.informativeText = Strings.permissionAlertMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: Strings.openSettingsButton)
        alert.addButton(withTitle: Strings.remindLaterButton)
        
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
    private func showRestartAlert() {
        if AppStore.shared.environment.shouldSuppressAlerts {
            logger.info("Suppressed Restart Alert (Testing Mode)")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = Strings.restartAlertTitle
        alert.informativeText = Strings.restartAlertMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: Strings.restartButton)
        alert.addButton(withTitle: Strings.remindLaterButton)
        
        // Bring app to front so alert is visible
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Restart the app
            restartApp()
        }
    }
    
    private func restartApp() {
        // Get the path to the app bundle
        guard let appPath = Bundle.main.bundlePath as String? else { return }
        
        // Use a small delay to allow the alert to close first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Launch new instance of the app
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [appPath]
            
            do {
                try task.run()
                // Now quit the current app
                NSApp.terminate(nil)
            } catch {
                self.logger.error("Failed to restart app: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func checkPermissions() {
        let permissions = AppStore.shared.environment.permissionsManager
        let isAx = permissions.checkAccessibility()
        let isInput = permissions.checkInputMonitoring()
        
        AppStore.shared.send(.security(.permissions(.didCheckStatus(accessibility: isAx, inputMonitoring: isInput))))
        
        // Only prompt for accessibility if not granted AND we haven't shown alert yet
        if !isAx && !hasShownInitialPermissionAlert && !AppStore.shared.environment.shouldSuppressAlerts {
            permissions.promptAccessibility()
        }
    }
}