//
//  Hotkeys.swift
//  CodeMask
//
//  Created by Amelia on 2026/1/8.
//

import Foundation

protocol HotkeyServiceProtocol {
    func registerHotkeys()
    func unregisterHotkeys()
}

enum Hotkeys {
    struct State: Equatable {
        var isMaskingRegistered: Bool = false
        var isRestorationRegistered: Bool = false
        var lastError: AppError?
    }
    
    enum Action {
        case didTriggerMasking
        case didTriggerRestoration
        case didFailToRegister(AppError)
    }
}
