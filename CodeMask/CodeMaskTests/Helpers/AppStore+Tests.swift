
//
//  AppStore+Tests.swift
//  CodeMask
//
//  Created by BMad Dev Agent on 2026/02/05.
//

@testable import CodeMask

extension AppStore {
    // Helper to simulate setting security state for tests
    @MainActor
    func setSecurity(accessibility: Bool, inputMonitoring: Bool) {
        let newState = Security.Permissions.State(
            isAccessibilityGranted: accessibility,
            isInputMonitoringGranted: inputMonitoring
        )
        self.security.permissions = newState
    }
}
