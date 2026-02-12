//
//  AppStore+Guardian.swift
//  CodeMask
//
//  Created by Edison on 2026/2/12.
//

import Foundation

extension AppStore {
    func reduce(guardian action: Guardian.Action) {
        switch action {
        case .didActivateBrowserApp(let bundleID):
            guardian.isBrowserFocused = true
            guardian.activeBrowserBundleID = bundleID
            evaluateDangerState()
            
        case .didDeactivateBrowserApp:
            guardian.isBrowserFocused = false
            guardian.activeBrowserBundleID = nil
            evaluateDangerState()
        }
    }
    
    /// Evaluates if the current state constitutes a "Danger" state (Browser Active + Secrets Present)
    func evaluateDangerState() {
        // Danger = Browser Detected AND Unmasked Secrets in Memory
        let isDanger = guardian.isBrowserFocused && session.hasSecrets
        
        // Dispatch session update
        // Note: send() is @MainActor, and we are inside a reducer called by send(),
        // effectively on @MainActor (AppStore is @MainActor).
        // However, reduce() is not isolated, but AppStore methods are.
        // We can call send() recursively.
        
        // Avoid infinite loops by checking distinctness if necessary,
        // but session reducer handles .didUpdateDanger idempotently or we trust the state change.
        // Session reducer: session.isDanger = isDanger.
        // It doesn't trigger other side effects itself, but MenuBarManager observes it.
        
        send(.session(.didUpdateDanger(isDanger: isDanger)))
    }

    /// Centralized mutation for session.hasSecrets to ensure danger is re-evaluated.
    func updateHasSecrets(_ hasSecrets: Bool) {
        guard session.hasSecrets != hasSecrets else { return }
        session.hasSecrets = hasSecrets
        evaluateDangerState()
    }
}
