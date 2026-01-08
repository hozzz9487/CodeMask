//
//  AppEnvironment.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import Foundation

/// Dependency Injection Container for CodeMask
/// Holds all system services and actors.
struct AppEnvironment {
    // Services
    var permissionsManager: PermissionsManagerProtocol
    var hotkeyManager: HotkeyServiceProtocol
    
    // var clipboardMonitor: ClipboardMonitorProtocol
    // var sessionActor: SessionActor
    
    init(
        permissionsManager: PermissionsManagerProtocol = PermissionsManager(),
        hotkeyManager: HotkeyServiceProtocol = GlobalHotkeyManager()
    ) {
        self.permissionsManager = permissionsManager
        self.hotkeyManager = hotkeyManager
    }
}
