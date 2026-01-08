//
//  GlobalHotkeyManager.swift
//  CodeMask
//
//  Created by Amelia on 2026/1/8.
//

import AppKit
import Carbon

final class GlobalHotkeyManager: HotkeyServiceProtocol {
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    
    // Unique signature for CodeMask
    private let signature: OSType = 0x434D534B // 'CMSK'
    
    // Hotkey IDs
    private enum HotkeyID: UInt32 {
        case masking = 1
        case restoration = 2
    }
    
    init() {}
    
    deinit {
        unregisterHotkeys()
    }
    
    func registerHotkeys() {
        // Cmd+Opt+C (Masking)
        // Cmd key code is 55, but Carbon uses virtual key codes. 
        // 'C' is 8, 'V' is 9.
        // Modifiers: cmdKey = 0x0100, optionKey = 0x0800
        
        let modifiers = UInt32(cmdKey | optionKey)
        
        register(id: .masking, keyCode: 8, modifiers: modifiers) // Cmd+Opt+C
        register(id: .restoration, keyCode: 9, modifiers: modifiers) // Cmd+Opt+V
        
        installEventHandler()
    }
    
    func unregisterHotkeys() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }
    
    private func register(id: HotkeyID, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id.rawValue)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id.rawValue] = ref
        } else {
            Task { @MainActor in
                AppStore.shared.send(.hotkeys(.didFailToRegister(.unknown)))
            }
        }
    }
    
    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, refCon) -> OSStatus in
            guard let event = event, let refCon = refCon else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr {
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refCon).takeUnretainedValue()
                manager.handleHotkeyTrigger(id: hotKeyID.id)
                return noErr
            }
            
            return CallNextEventHandler(nextHandler, event)
        }, 1, &eventSpec, pointer, nil)
    }
    
    private func handleHotkeyTrigger(id: UInt32) {
        guard let hotkeyID = HotkeyID(rawValue: id) else { return }
        
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