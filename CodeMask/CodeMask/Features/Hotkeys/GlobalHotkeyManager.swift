//
//  GlobalHotkeyManager.swift
//  CodeMask
//
//  Created by Amelia on 2026/1/8.
//

import AppKit
import Carbon
import os

/// Global hotkey manager using macOS Carbon framework for system-wide keyboard shortcuts.
///
/// Registers `Cmd+Opt+C` for masking and `Cmd+Opt+V` for restoration.
/// These shortcuts work system-wide regardless of the active application.
///
/// - Note: Requires proper lifecycle management. Call `registerHotkeys()` once at app launch
///         and `unregisterHotkeys()` or rely on `deinit` for cleanup.
final class GlobalHotkeyManager: HotkeyServiceProtocol {
    private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "GlobalHotkeyManager")
    private let registrationLock = NSLock()
    
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?
    
    /// Unique signature identifying CodeMask hotkeys to avoid collisions with other apps
    private let signature: OSType = 0x434D534B // 'CMSK'
    
    /// Virtual key codes from Carbon framework
    private enum VirtualKeyCode: UInt32 {
        case c = 8  // Command+Option+C for masking
        case v = 9  // Command+Option+V for restoration
    }
    
    /// Hotkey IDs
    private enum HotkeyID: UInt32, CustomStringConvertible {
        case masking = 1
        case restoration = 2
        
        var description: String {
            switch self {
            case .masking: return "Masking (Cmd+Opt+C)"
            case .restoration: return "Restoration (Cmd+Opt+V)"
            }
        }
    }
    
    init() {}
    
    deinit {
        logger.debug("Deinitializing GlobalHotkeyManager")
        unregisterHotkeys()
    }
    
    /// Registers system-wide hotkeys and installs the event handler.
    /// Safe to call multiple times; uses locking and checks if already registered.
    func registerHotkeys() {
        registrationLock.lock()
        defer { registrationLock.unlock() }
        
        logger.info("Registering global hotkeys...")
        
        // Change from optionKey to controlKey to match Cmd+Ctrl+C requirement
        let modifiers = UInt32(cmdKey | controlKey)
        
        register(id: .masking, keyCode: VirtualKeyCode.c.rawValue, modifiers: modifiers)
        register(id: .restoration, keyCode: VirtualKeyCode.v.rawValue, modifiers: modifiers)
        
        if eventHandlerRef == nil {
            installEventHandler()
        }
    }
    
    /// Unregisters all hotkeys and cleans up resources, including the event handler.
    func unregisterHotkeys() {
        registrationLock.lock()
        defer { registrationLock.unlock() }
        
        logger.info("Unregistering global hotkeys...")
        
        for (id, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
            logger.debug("Unregistered hotkey ID: \(id)")
        }
        hotKeyRefs.removeAll()
        
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
            logger.debug("Removed event handler")
            
            // If we used passRetained, we would release here.
            // But we are currently using passUnretained assuming the manager 
            // is kept alive by the AppStore/Environment.
        }
        
        Task { @MainActor in
            AppStore.shared.hotkeys.isMaskingRegistered = false
            AppStore.shared.hotkeys.isRestorationRegistered = false
        }
    }
    
    private func register(id: HotkeyID, keyCode: UInt32, modifiers: UInt32) {
        if hotKeyRefs[id.rawValue] != nil {
            logger.debug("Hotkey \(id) already registered, skipping")
            return
        }
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id.rawValue)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id.rawValue] = ref
            logger.info("Successfully registered hotkey: \(id)")
            
            Task { @MainActor in
                switch id {
                case .masking:
                    AppStore.shared.hotkeys.isMaskingRegistered = true
                case .restoration:
                    AppStore.shared.hotkeys.isRestorationRegistered = true
                }
            }
        } else {
            let error: AppError
            switch status {
            case -9869: // eventHotKeyAlreadyRegisteredErr
                error = .hotkeyConflict(hotkeyName: id.description)
                logger.warning("Hotkey conflict for \(id): status \(status)")
            case -50: // eventInvalidParamErr / paramErr
                error = .invalidConfiguration("Invalid hotkey parameters")
                logger.error("Invalid hotkey parameters for \(id): status \(status)")
            default:
                error = .unknown
                logger.error("Failed to register hotkey \(id): status \(status)")
            }
            
            Task { @MainActor in
                AppStore.shared.send(.hotkeys(.didFailToRegister(error)))
            }
        }
    }
    
    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // We use passUnretained because the manager is owned by AppStore.shared.environment,
        // which lives for the entire application lifetime.
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, refCon) -> OSStatus in
            guard let event = event, let refCon = refCon else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr {
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refCon).takeUnretainedValue()
                manager.handleHotkeyTrigger(id: hotKeyID.id)
                return noErr
            }
            
            return CallNextEventHandler(nextHandler, event)
        }, 1, &eventSpec, pointer, &handlerRef)
        
        if status == noErr {
            eventHandlerRef = handlerRef
            logger.debug("Installed event handler successfully")
        } else {
            logger.error("Failed to install event handler: status \(status)")
        }
    }
    
    private func handleHotkeyTrigger(id: UInt32) {
        guard let hotkeyID = HotkeyID(rawValue: id) else { 
            logger.error("Received trigger for unknown hotkey ID: \(id)")
            return 
        }
        
        logger.info("Hotkey triggered: \(hotkeyID)")
        
        Task { @MainActor in
            switch hotkeyID {
            case .masking:
                AppStore.shared.send(.hotkeys(.didTriggerMasking))
            case .restoration:
                AppStore.shared.send(.hotkeys(.didTriggerRestoration))
            }
        }
    }
}