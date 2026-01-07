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
        // Attempt to create an event tap to check for Input Monitoring permission.
        // If permission is missing, this usually returns nil.
        // We use a dummy tap that passes events through.
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, event, _ in
                // Pass the event through untouched
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        )
        
        guard let validTap = tap else { return false }
        
        // If we got a tap, we likely have permission.
        // Explicitly check if it is enabled.
        return CGEvent.tapIsEnabled(tap: validTap)
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
