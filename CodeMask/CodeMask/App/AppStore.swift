//
//  AppStore.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import SwiftUI
import Combine

// MARK: - Global State
@MainActor
@Observable
final class AppStore {
    // Single instance for the application
    static let shared = AppStore(environment: AppEnvironment())
    
    // Dependencies
    var environment: AppEnvironment
    
    // Feature States
    var security = Security.State()
    var hotkeys = Hotkeys.State()
    var session = Session.State()
    
    // Track previous permission state to detect changes
    @ObservationIgnored private var previousPermissionState: Security.Permissions.State? = nil
    
    // Computed props for convenience
    var isSafe: Bool { security.permissions.isAccessibilityGranted && security.permissions.isInputMonitoringGranted }
    
    // Combine bridge for non-SwiftUI observers (e.g. AppDelegate, MenuBarManager)
    // Using @ObservationIgnored to prevent observation loops if these were used in reducers
    @ObservationIgnored private let errorSubject = PassthroughSubject<AppError?, Never>()
    @ObservationIgnored private let isSafeSubject = PassthroughSubject<Bool, Never>()
    @ObservationIgnored private let permissionChangedSubject = PassthroughSubject<Void, Never>()
    
    var errorPublisher: AnyPublisher<AppError?, Never> { errorSubject.eraseToAnyPublisher() }
    var isSafePublisher: AnyPublisher<Bool, Never> { isSafeSubject.eraseToAnyPublisher() }
    var permissionChangedPublisher: AnyPublisher<Void, Never> { permissionChangedSubject.eraseToAnyPublisher() }
    
    init(environment: AppEnvironment) {
        self.environment = environment
    }
    
    // MARK: - Action Dispatch
    func send(_ action: AppAction) {
        switch action {
        case .didLaunch:
            // Future: Check permissions, start services
            break
            
        case .security(let action):
            reduce(security: action)
            
        case .hotkeys(let action):
            reduce(hotkeys: action)
            
        case .session(let action):
            reduce(session: action)
        }
    }
    
    // MARK: - Reducers
    private func reduce(session action: Session.Action) {
        switch action {
        case .didSecureData(let token):
            session.sessionID = token
            
        case .didRetrieveData:
            // Transient data, not stored in state
            break
            
        case .didFail(let error):
            security.lastError = error
            errorSubject.send(error)
        }
    }
    
    private func reduce(hotkeys action: Hotkeys.Action) {
        switch action {
        case .didTriggerMasking:
            hotkeys.lastTriggeredHotkey = action
            hotkeys.lastHotkeyTriggerTime = Date()
            // Future: Trigger masking engine (Story 1.4)
            
        case .didTriggerRestoration:
            hotkeys.lastTriggeredHotkey = action
            hotkeys.lastHotkeyTriggerTime = Date()
            // Future: Trigger restoration engine (Story 1.6)
            
        case .didFailToRegister(let error):
            hotkeys.lastError = error
        }
    }

    private func reduce(security action: Security.Action) {
        switch action {
        case .permissions(let permissionAction):
            switch permissionAction {
            case .didCheckStatus(let accessibility, let inputMonitoring):
                let newState = Security.Permissions.State(
                    isAccessibilityGranted: accessibility,
                    isInputMonitoringGranted: inputMonitoring
                )
                
                // Only emit events if permissions actually changed
                if previousPermissionState != newState {
                    security.permissions = newState
                    previousPermissionState = newState
                    
                    // Notify subscribers only on actual changes
                    isSafeSubject.send(isSafe)
                    permissionChangedSubject.send(())
                }
            }
            
        case .didEncounterError(let error):
            security.lastError = error
            errorSubject.send(error)
            
        case .didClearError:
            security.lastError = nil
            errorSubject.send(nil)
        }
    }
}

// MARK: - Global Action Enum
enum AppAction {
    case didLaunch
    case security(Security.Action)
    case hotkeys(Hotkeys.Action)
    case session(Session.Action)
}

enum AppError: Error, Equatable {
    case permissionsCheckFailed
    case hotkeyConflict(hotkeyName: String)
    case invalidConfiguration(String)
    case unknown
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionsCheckFailed, .permissionsCheckFailed): return true
        case (.hotkeyConflict(let l), .hotkeyConflict(let r)): return l == r
        case (.invalidConfiguration(let l), .invalidConfiguration(let r)): return l == r
        case (.unknown, .unknown): return true
        default: return false
        }
    }
}

// MARK: - Feature Namespaces

enum Security {
    struct State {
        var permissions = Permissions.State()
        var lastError: AppError?
    }
    
    enum Action {
        case permissions(Permissions.Action)
        case didEncounterError(AppError)
        case didClearError
    }
    
    enum Permissions {
        struct State: Equatable {
            var isAccessibilityGranted: Bool = false
            var isInputMonitoringGranted: Bool = false
        }
        
        enum Action {
            case didCheckStatus(accessibility: Bool, inputMonitoring: Bool)
        }
    }
}
