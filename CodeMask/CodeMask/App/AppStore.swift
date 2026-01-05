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
        }
    }
}

// MARK: - Global Action Enum
enum AppAction {
    case didLaunch
    case security(Security.Action)
}

// MARK: - Feature Namespaces

enum Security {
    struct State {
        var permissions = Permissions.State()
    }
    
    enum Action {
        case permissions(Permissions.Action)
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
