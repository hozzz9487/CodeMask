# Story 1.1: Core App & Permissions Scaffolding

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a native macOS application structure with necessary system permissions,
so that the app can run securely in the background and access the system clipboard and shortcuts.

## Acceptance Criteria

1. **Application Scaffolding**: Project is initialized with Custom Native Scaffolding (Swift/SwiftUI/AppKit) targeting macOS 26.
2. **Menu Bar Only**: The application runs as an `LSUIElement` (Agent) with no Dock icon.
3. **Permission Request**: On launch, proactively request "Accessibility" and "Input Monitoring" permissions if not granted.
4. **Status Indication**: Menu Bar icon displays "Safe" (Grey/Blue) status if permissions are granted.
5. **Project Structure**: Directory structure matches the defined "Feature-First" architecture.

## Tasks / Subtasks

- [ ] Initialize Xcode Project (CodeMask) targeting macOS 26
  - [ ] Configure Info.plist:
    - [ ] `LSUIElement = YES` (Agent App)
    - [ ] `NSAppleEventsUsageDescription` (Explain need for Accessibility to paste text)
    - [ ] `NSSystemAdministrationUsageDescription` (Explain need for Input Monitoring to detect shortcuts)
  - [ ] Set up Feature-First directory structure (App, Core, Features, Resources)
- [ ] Implement `CodeMaskApp.swift` entry point
- [ ] Implement `AppEnvironment.swift` (Dependency Injection Container)
- [ ] Create `AppStore` singleton (Architecture Root) injecting `AppEnvironment`
- [ ] Implement `PermissionsManager` (Core/Security)
  - [ ] Check Accessibility status
  - [ ] Check Input Monitoring status
  - [ ] Request permissions flow
- [ ] Implement `MenuBarController` (Features/UI/Menu Bar)
  - [ ] Create `NSStatusItem`
  - [ ] Logic for icon state (Grey/Blue) based on permissions
- [ ] Verify "Safe" state logic in `AppStore`

## Dev Notes

### Architecture Compliance

- **Pattern**: Native Unidirectional Flow (Redux-lite).
- **Store**: Create `AppStore` as an `@Observable final class` isolated to `@MainActor` for UI state.
- **Dependency Injection**: Use `AppEnvironment` to inject dependencies into `AppStore`.
- **Permissions**: Wrap system API calls in a `PermissionsServiceProtocol` to allow mocking in tests.
- **Structure**: STRICTLY follow the folder structure defined in `architecture.md`.

### Technical Requirements

- **Swift Version**: 6.2 (Strict Concurrency enabled).
- **UI Framework**: SwiftUI for Views, AppKit (`NSStatusBar`) for the menu bar.
- **State Management**: Actions must be **Events** (e.g., `.didLaunch`, `.permissionsChanged`), NEVER Commands.
- **Namespace**: Wrap Feature State and Actions in a namespace enum to prevent pollution.

  ```swift
  // Example for Permissions namespace structure
  enum Security {
      enum Permissions {
          struct State: Equatable {
              var isAccessibilityGranted: Bool = false
          }
          enum Action {
              case didCheckStatus(accessibility: Bool, inputMonitoring: Bool)
              case didTapOpenSettings
          }
      }
  }
  ```

### Critical Implementation Rules (Do Not Miss)

- **MainActor Trap**: Ensure all `NSStatusBar` updates happen on `@MainActor`.
- **Feature Namespacing**: Do not pollute the global namespace.
- **Error Propagation**: If permission fails, dispatch a `.didEncounterError` action; do not fail silently.

### Project Structure Notes

Ensure the following files are created in their correct locations:
- `CodeMask/App/CodeMaskApp.swift`
- `CodeMask/App/AppStore.swift`
- `CodeMask/App/AppEnvironment.swift`
- `CodeMask/Core/Security/PermissionsManager.swift`
- `CodeMask/Features/UI/Menu Bar/MenuBarManager.swift`

### References

- [Architecture: Project Structure](_bmad-output/architecture.md#project-structure--boundaries)
- [Epic 1.1 Criteria](_bmad-output/epics.md#story-11-core-app--permissions-scaffolding)
- [UX: Menu Bar Status](_bmad-output/ux-design-specification.md#story-21-menu-bar-status-icon)

## Dev Agent Record

### Agent Model Used
Gemini Pro 1.5 (Simulated)

### Debug Log References
- None

### Completion Notes List
- Initial scaffolding story created.
- Epic 1 marked as in-progress.

### File List
- _bmad-output/implementation-artifacts/1-1-core-app-permissions-scaffolding.md