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
    var clipboard = Clipboard.State()
    var hud = HUD.State()
    
    // Internal Task Management
    private var maskingTask: Task<Void, Never>?
    private var hudAutoHideTask: Task<Void, Never>?
    
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
        
        // Initial Rule Load (Story 1.5 readiness)
        Task {
            _ = await environment.regexEngine.updateRules(Clipboard.Rule.defaults)
        }
    }
    
    // MARK: - Action Dispatch
    func send(_ action: AppAction) {
        switch action {
        case .didLaunch:
            // Prepare feedback resources (Story 1.5 AC 3)
            environment.haptics.prepare()
            environment.audio.prepare(sound: .tink)
            
        case .security(let action):
            reduce(security: action)
            
        case .hotkeys(let action):
            reduce(hotkeys: action)
            
        case .session(let action):
            reduce(session: action)
            
        case .clipboard(let action):
            reduce(clipboard: action)
            
        case .hud(let action):
            reduce(hud: action)
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
            // Trigger masking engine (Story 1.5)
            send(.clipboard(.startMasking))
            
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
    
    private func reduce(clipboard action: Clipboard.Action) {
        switch action {
        case .startMasking:
            // 1. Cancel previous task (Conflated Task Pattern)
            maskingTask?.cancel()
            
            clipboard.isMasking = true
            
            // 2. Start new detached task (Non-Blocking)
            maskingTask = Task.detached { [weak self, environment = self.environment] in
                // Check for cancellation early
                if Task.isCancelled { return }
                
                // Read
                guard let content = await environment.pasteboard.string(), !content.isEmpty else {
                    // Don't use defer path for intentional completion
                    await self?.send(.clipboard(.maskingSequenceCompleted(.success(false))))
                    return
                }
                
                if Task.isCancelled { return }
                
                // Mask
                let result = await environment.regexEngine.mask(content)
                
                if Task.isCancelled { return }
                
                // Branching
                if !result.secrets.isEmpty {
                    // Store
                    // Map Token.id (String) -> Secret
                    let secretsBatch = Dictionary(uniqueKeysWithValues: result.secrets.map { ($0.key.id, $0.value) })
                    await environment.session.store(batch: secretsBatch)
                    
                    // Write
                    await environment.pasteboard.setString(result.maskedString)
                    
                    await self?.send(.clipboard(.maskingSequenceCompleted(.success(true))))
                } else {
                    // No-op write
                    await self?.send(.clipboard(.maskingSequenceCompleted(.success(false))))
                }
            }
            
        case .maskingSequenceCompleted(let result):
            // Clean up task reference
            maskingTask = nil
            clipboard.isMasking = false
            
            switch result {
            case .success(let masked):
                // Feedback
                if masked {
                    // Success with masking
                    environment.haptics.play(.generic)
                    environment.audio.playSystemSound(.tink)
                    send(.hud(.show(message: "Secured", type: .success)))
                } else {
                    // No secrets found
                    environment.haptics.play(.generic)
                    environment.audio.playSystemSound(.tink)
                    send(.hud(.show(message: "Secured", type: .success)))
                }
                
            case .failure:
                environment.haptics.play(.alignment)
                environment.audio.playSystemSound(.alert)
                send(.hud(.show(message: "Error", type: .error)))
            }
        }
    }
    
    private func reduce(hud action: HUD.Action) {
        switch action {
        case .show(let message, let type):
            // Cancel previous auto-hide task (Conflated Task Pattern)
            hudAutoHideTask?.cancel()
            
            hud.message = message
            hud.type = type
            hud.isVisible = true
            
            // Auto hide
            hudAutoHideTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
                if !Task.isCancelled {
                    send(.hud(.hide))
                }
            }
            
        case .hide:
            // Clean up task reference
            hudAutoHideTask?.cancel()
            hudAutoHideTask = nil
            
            hud.message = ""
            hud.isVisible = false
        }
    }
}

// MARK: - Global Action Enum
enum AppAction {
    case didLaunch
    case security(Security.Action)
    case hotkeys(Hotkeys.Action)
    case session(Session.Action)
    case clipboard(Clipboard.Action)
    case hud(HUD.Action)
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
