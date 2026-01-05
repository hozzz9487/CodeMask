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
        // Attempt to create an event tap.
        // If we lack Input Monitoring permission, this returns nil (or a disabled tap).
        // We use a dummy tap that doesn't actually intercept anything important.
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, _, _ in return Unmanaged.passUnretained(CGEvent(source: nil)!) },
            userInfo: nil
        )
        
        guard let validTap = tap else { return false }
        
        // If the tap is created but disabled, it might mean we lack permission (or it was disabled by system)
        let isEnabled = CGEvent.tapIsEnabled(tap: validTap)
        
        // Clean up not strictly necessary for CFMachPort but good practice if we were keeping it.
        // For a check, we just discard it.
        return isEnabled
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
