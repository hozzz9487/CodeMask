//
//  PermissionsManager.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import AppKit
import ApplicationServices
import os

protocol PermissionsManagerProtocol {
    func checkAccessibility() -> Bool
    func checkInputMonitoring() -> Bool
    func promptAccessibility()
}

final class PermissionsManager: PermissionsManagerProtocol {
    typealias TapProvider = (CGEventTapLocation, CGEventTapPlacement, CGEventTapOptions, CGEventMask, @escaping CGEventTapCallBack, UnsafeMutableRawPointer?) -> CFMachPort?
    
    private let tapProvider: TapProvider
    private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "PermissionsManager")
    
    init(tapProvider: @escaping TapProvider = CGEvent.tapCreate) {
        self.tapProvider = tapProvider
    }
    
    func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func checkInputMonitoring() -> Bool {
        // Check Input Monitoring permission by attempting to create an event tap
        // If permission is not granted, tapCreate returns nil immediately
        // If permission is granted, tap is created successfully
        
        let tap = tapProvider(
            .cgSessionEventTap,
            .headInsertEventTap,
            .defaultTap,
            CGEventMask(1 << CGEventType.keyDown.rawValue),
            { _, _, event, _ in
                let optionalEvent: CGEvent? = event
                guard let validEvent = optionalEvent else { return nil }
                return Unmanaged.passUnretained(validEvent)
            },
            nil
        )
        
        guard let validTap = tap else {
            self.logger.debug("checkInputMonitoring: tap creation failed -> DENIED")
            return false
        }
        
        // Tap was created - check if it can actually be enabled
        CGEvent.tapEnable(tap: validTap, enable: true)
        defer { CGEvent.tapEnable(tap: validTap, enable: false) }
        
        let isEnabled = CGEvent.tapIsEnabled(tap: validTap)
        self.logger.debug("checkInputMonitoring: tap created and enabled -> \(isEnabled ? "GRANTED" : "DENIED")")
        
        return isEnabled
    }
    
    func promptAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        AXIsProcessTrustedWithOptions(options)
    }
}
