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
    private var restorationTask: Task<Void, Never>?
    private var hudAutoHideTask: Task<Void, Never>?
    
    // Track previous permission state to detect changes
    @ObservationIgnored private var previousPermissionState: Security.Permissions.State? = nil
    
    // Computed props for convenience
    var isSafe: Bool { security.permissions.isAccessibilityGranted && security.permissions.isInputMonitoringGranted }
    var securityStatus: Session.SecurityStatus { session.securityStatus }
    
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
        session.isStatusKnown = isSafe
        
        // Initial Rule Load (Story 1.5 readiness + Story 1.7 Mobile Presets)
        Task {
            // Start with hardcoded defaults
            var rules = Clipboard.Rule.defaults
            
            // Load Mobile Presets resource
            do {
                let mobileRules = try Clipboard.PresetLoader.loadMobilePresets()
                rules.append(contentsOf: mobileRules)
            } catch {
                // Non-critical but observable failure
                print("Failed to load Mobile Presets: \(error)")
                
                // Dispatch error to UI/State so it isn't silent
                // Must ensure self is available; Task captures self strongly if not careful, 
                // but here we are inside init -> Task. 
                await self.send(.security(.didEncounterError(.invalidConfiguration("Mobile Presets Failed: \(error.localizedDescription)"))))
            }
            
            _ = await environment.regexEngine.updateRules(rules)
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
    
    /// Reset the store to initial state (Testing only)
    @MainActor
    func reset() {
        self.environment = AppEnvironment()
        self.security = Security.State()
        self.hotkeys = Hotkeys.State()
        self.session = Session.State()
        self.clipboard = Clipboard.State()
        self.hud = HUD.State()
        self.previousPermissionState = nil
        // Note: subjects don't need reset as they are Passthrough
    }
    
    // MARK: - Reducers
    private func reduce(session action: Session.Action) {
        switch action {
        case .didSecureData(let token):
            session.sessionID = token
            
        case .didRetrieveData:
            // Transient data, not stored in state
            break
            
        case .didUpdateDanger(let isDanger):
            session.isDanger = isDanger
            
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
            // Trigger restoration engine (Story 1.6)
            send(.clipboard(.startRestoration))
            
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
                    
                    session.isStatusKnown = accessibility && inputMonitoring
                    
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
                
                // NEW: Trigger automated Copy action from the current app
                await environment.keyboard.simulateCopy()
                
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
                    session.hasSecrets = true
                    // Success with masking
                    environment.haptics.play(.generic)
                    environment.audio.playSystemSound(.tink)
                    send(.hud(.show(message: "Secured", type: .success)))
                } else {
                    // No secrets found - Code Review Fix: Use clearer feedback
                    environment.haptics.play(.generic)
                    environment.audio.playSystemSound(.tink)
                    send(.hud(.show(message: "No Secrets", type: .neutral)))
                }
                
            case .failure:
                environment.haptics.play(.alignment)
                environment.audio.playSystemSound(.alert)
                send(.hud(.show(message: "Error", type: .error)))
            }
            
        case .startRestoration:
            // 1. Cancel previous task (Conflated Task Pattern)
            restorationTask?.cancel()
            
            // 2. Start new detached task (Non-Blocking)
            restorationTask = Task.detached { [weak self, environment = self.environment] in
                if Task.isCancelled { return }
                
                // 1. Read
                guard let content = await environment.pasteboard.string(), !content.isEmpty else {
                    await self?.send(.clipboard(.restorationSequenceCompleted(.noTokensFound)))
                    return
                }
                
                // 2. Scan (Pattern: {{CM_T:[a-f0-9]{12}}})
                let ids = await environment.regexEngine.scanForTokenIDs(content)
                
                if ids.isEmpty {
                    await self?.send(.clipboard(.restorationSequenceCompleted(.noTokensFound)))
                    return
                }
                
                // 3. Lookup
                let mapping = await environment.session.resolve(tokens: ids)
                
                // 4. Reconstruct
                let restoredContent = await environment.regexEngine.replace(content: content, mapping: mapping)
                
                // 5. Action Branching - Restoration Occurred
                // Secure Paste Dance
                
                let maskedContent = content
                
                // Prepare Secret
                await environment.pasteboard.setString(restoredContent)
                
                // Execute Paste
                await environment.keyboard.simulatePaste()
                
                // Wait for system consumption (200ms) with Cancellation handling
                do {
                    try await Task.sleep(nanoseconds: 200_000_000)
                } catch {
                    // Task cancelled or interrupted, but we MUST proceed to cleanup
                }
                
                // Restore Safety (runs regardless of cancellation during sleep)
                await environment.pasteboard.setString(maskedContent)
                
                // Determine success/partial - Code Review Fix: 
                // Check the actual restored string for error markers for 100% accuracy
                let isPartial = restoredContent.contains(">>MISSING_SECRET<<")
                
                if isPartial {
                    await self?.send(.clipboard(.restorationSequenceCompleted(.partialSuccess)))
                } else {
                    await self?.send(.clipboard(.restorationSequenceCompleted(.success)))
                }
            }
            
        case .restorationSequenceCompleted(let status):
            restorationTask = nil
            
            switch status {
            case .success:
                environment.haptics.play(.generic) // "Tap" implied by AC
                environment.audio.playSystemSound(.tink)
                send(.hud(.show(message: "Restored", type: .success)))
                
            case .partialSuccess:
                environment.haptics.play(.alignment) // Warning
                // AC says "Thump" + Alignment. .alert usually maps to Thump/Basso.
                environment.audio.playSystemSound(.alert)
                send(.hud(.show(message: "Missing Secrets", type: .error)))
                
            case .noTokensFound:
                // AC: HUD "No Tokens" (Grey). No paste modification.
                send(.hud(.show(message: "No Tokens", type: .info)))
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
