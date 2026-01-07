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
        
        // If we got a tap, we likely have permission.
        // Explicitly check if it is enabled.
        let isEnabled = CGEvent.tapIsEnabled(tap: validTap)
        
        // CRITICAL: Disable the tap to release resources and prevent leaks.
        // Although CFMachPort is ref-counted, explicitly disabling ensures it stops monitoring.
        CGEvent.tapEnable(tap: validTap, enable: false)
        
        return isEnabled
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
