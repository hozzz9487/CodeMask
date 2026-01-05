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
    private let environment: AppEnvironment
    
    // Feature States
    var security = Security.State()
    
    // Computed props for convenience
    var isSafe: Bool { security.permissions.isAccessibilityGranted && security.permissions.isInputMonitoringGranted }
    
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
        }
    }
    
    // MARK: - Reducers
    private func reduce(security action: Security.Action) {
        switch action {
        case .permissions(let permissionAction):
            switch permissionAction {
            case .didCheckStatus(let accessibility, let inputMonitoring):
                security.permissions.isAccessibilityGranted = accessibility
                security.permissions.isInputMonitoringGranted = inputMonitoring
            }
            
        case .didEncounterError(let error):
            security.lastError = error
            // In a real app, we might also toggle a flag to show an alert
        }
    }
}

// MARK: - Global Action Enum
enum AppAction {
    case didLaunch
    case security(Security.Action)
}

enum AppError: Error, Equatable {
    case permissionsCheckFailed
    case unknown
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionsCheckFailed, .permissionsCheckFailed): return true
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
