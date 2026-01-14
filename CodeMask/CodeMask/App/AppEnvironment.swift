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
    var session: SessionStorageProtocol
    
    // var clipboardMonitor: ClipboardMonitorProtocol
    
    init(
        permissionsManager: PermissionsManagerProtocol = PermissionsManager(),
        hotkeyManager: HotkeyServiceProtocol = GlobalHotkeyManager(),
        session: SessionStorageProtocol = SessionActor()
    ) {
        self.permissionsManager = permissionsManager
        self.hotkeyManager = hotkeyManager
        self.session = session
    }
}
