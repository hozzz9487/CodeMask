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
    typealias TapProvider = (CGEventTapLocation, CGEventTapPlacement, CGEventTapOptions, CGEventMask, @escaping CGEventTapCallBack, UnsafeMutableRawPointer?) -> CFMachPort?
    
    private let tapProvider: TapProvider
    
    init(tapProvider: @escaping TapProvider = CGEvent.tapCreate) {
        self.tapProvider = tapProvider
    }
    
    func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func checkInputMonitoring() -> Bool {
        // Attempt to create an event tap to check for Input Monitoring permission.
        // If permission is missing, this usually returns nil.
        // We use a dummy tap that passes events through.
        let tap = tapProvider(
            .cgSessionEventTap,
            .headInsertEventTap,
            .defaultTap,
            CGEventMask(1 << CGEventType.keyDown.rawValue),
            { _, _, event, _ in
                // Fix: CGEvent callback nil guard - crash on permission denied
                // Use a local variable to bridge to optional if necessary
                let optionalEvent: CGEvent? = event
                guard let validEvent = optionalEvent else { return nil }
                return Unmanaged.passUnretained(validEvent)
            },
            nil
        )
        
        guard let validTap = tap else { return false }
        
        // CRITICAL: Ensure the tap is disabled even if tapIsEnabled throws an exception.
        // This prevents resource leaks on error paths.
        defer { CGEvent.tapEnable(tap: validTap, enable: false) }
        
        // If we got a tap, we likely have permission.
        // Explicitly check if it is enabled.
        let isEnabled = CGEvent.tapIsEnabled(tap: validTap)
        
        return isEnabled
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
