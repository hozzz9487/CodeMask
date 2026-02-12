//
//  BrowserContextDetector.swift
//  CodeMask
//
//  Created by Edison on 2026/2/12.
//

import AppKit

protocol BrowserContextDetectorProtocol: Sendable {
    var events: AsyncStream<Guardian.Action> { get }
    @MainActor func startMonitoring()
    @MainActor func stopMonitoring()
}

@MainActor
final class BrowserContextDetector: BrowserContextDetectorProtocol {
    
    // MARK: - Constants
    
    static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "company.thebrowser.Browser",   // Arc
        "com.microsoft.edgemac",        // Microsoft Edge
        "com.brave.Browser"             // Brave
    ]
    
    // MARK: - State
    
    private var observer: NSObjectProtocol?
    private let eventStream: AsyncStream<Guardian.Action>
    private let eventContinuation: AsyncStream<Guardian.Action>.Continuation
    
    nonisolated var events: AsyncStream<Guardian.Action> { eventStream }
    
    // MARK: - API
    
    nonisolated init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Guardian.Action.self)
        self.eventStream = stream
        self.eventContinuation = continuation
    }
    
    deinit {
        // NotificationCenter.default.removeObserver is thread-safe
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        eventContinuation.finish()
    }
    
    func startMonitoring() {
        guard observer == nil else { return }
        
        // Subscribe to NSWorkspace notification
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Swift 6: explicitly hop to MainActor or wrap in Task to satisfy isolation
            Task { @MainActor [weak self] in
                self?.handleAppActivation(notification)
            }
        }
        
        // Initial Check
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            checkApplication(frontApp)
        }
    }
    
    func stopMonitoring() {
        if let observer = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        checkApplication(app)
    }
    
    private func checkApplication(_ app: NSRunningApplication) {
        checkBundleID(app.bundleIdentifier)
    }
    
    /// Internal for testing
    func checkBundleID(_ bundleID: String?) {
        guard let bundleID, !bundleID.isEmpty else {
            eventContinuation.yield(.didDeactivateBrowserApp)
            return
        }
        
        if Self.browserBundleIDs.contains(bundleID) {
            eventContinuation.yield(.didActivateBrowserApp(bundleID: bundleID))
        } else {
            eventContinuation.yield(.didDeactivateBrowserApp)
        }
    }
}
