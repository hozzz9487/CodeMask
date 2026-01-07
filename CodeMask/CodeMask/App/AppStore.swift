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
    let environment: AppEnvironment
    
    // Feature States
    var security = Security.State()
    
    // Computed props for convenience
    var isSafe: Bool { security.permissions.isAccessibilityGranted && security.permissions.isInputMonitoringGranted }
    
    // Combine bridge for non-SwiftUI observers (e.g. AppDelegate, MenuBarManager)
    // Using @ObservationIgnored to prevent observation loops if these were used in reducers
    @ObservationIgnored private let errorSubject = PassthroughSubject<AppError?, Never>()
    @ObservationIgnored private let isSafeSubject = PassthroughSubject<Bool, Never>()
    
    var errorPublisher: AnyPublisher<AppError?, Never> { errorSubject.eraseToAnyPublisher() }
    var isSafePublisher: AnyPublisher<Bool, Never> { isSafeSubject.eraseToAnyPublisher() }
    
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
        
        // Notify publishers after state change
        isSafeSubject.send(isSafe)
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