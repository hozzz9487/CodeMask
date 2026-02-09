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
    
    var pasteboard: PasteboardServiceProtocol
    var haptics: HapticServiceProtocol
    var audio: AudioServiceProtocol
    var regexEngine: Clipboard.RegexEngineProtocol
    var keyboard: KeyboardServiceProtocol
    
    /// Returns true if the application is currently running within a testing environment (XCTest).
    static var isRunningUnitTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    init(
        permissionsManager: PermissionsManagerProtocol = PermissionsManager(),
        hotkeyManager: HotkeyServiceProtocol = GlobalHotkeyManager(),
        session: SessionStorageProtocol = SessionActor(),
        pasteboard: PasteboardServiceProtocol = LivePasteboardService(),
        haptics: HapticServiceProtocol = LiveHapticService(),
        audio: AudioServiceProtocol = LiveAudioService(),
        regexEngine: Clipboard.RegexEngineProtocol = Clipboard.RegexEngine(),
        keyboard: KeyboardServiceProtocol = LiveKeyboardService()
    ) {
        self.permissionsManager = permissionsManager
        self.hotkeyManager = hotkeyManager
        self.session = session
        self.pasteboard = pasteboard
        self.haptics = haptics
        self.audio = audio
        self.regexEngine = regexEngine
        self.keyboard = keyboard
    }
}
