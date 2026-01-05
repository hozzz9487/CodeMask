//
//  PermissionsManager.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import AppKit
import ApplicationServices

protocol PermissionsManagerProtocol {
    func checkAccessibility() -> Bool
    func checkInputMonitoring() -> Bool
    func promptAccessibility()
}

final class PermissionsManager: PermissionsManagerProtocol {
    func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func checkInputMonitoring() -> Bool {
        // Input Monitoring is trickier to check passively without triggering a prompt or using IOHID API hacks.
        // For MVP, checking Accessibility is the primary gate.
        // We will assume Input Monitoring needs to be requested via a dummy event listener later.
        // For now, return a placeholder true or rely on AX.
        return true 
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
