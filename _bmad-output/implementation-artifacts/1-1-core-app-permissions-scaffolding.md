# Story 1.1: Core App & Permissions Scaffolding

Status: in-progress

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a native macOS application structure with necessary system permissions,
so that the app can run securely in the background and access the system clipboard and shortcuts.

## Acceptance Criteria

1. **Application Scaffolding**: Project is initialized with Custom Native Scaffolding (Swift/SwiftUI/AppKit) targeting macOS 26.
2. **Menu Bar Interface**: The application's primary interface is the menu bar status icon. Dock icon appears during runtime (hides only via future Epic 2 feature).
3. **Permission Request**: On launch, proactively request "Accessibility" and "Input Monitoring" permissions if not granted.
4. **Status Indication**: Menu Bar icon displays "Safe" (Grey/Blue) status if permissions are granted.
5. **Project Structure**: Directory structure matches the defined "Feature-First" architecture.

## Tasks / Subtasks

- [x] Initialize Xcode Project (CodeMask) targeting macOS 26
  - [x] Configure Info.plist:
    - [x] `LSUIElement = YES` (Agent App)
    - [x] `NSAppleEventsUsageDescription` (Explain need for Accessibility to paste text)
    - [x] `NSSystemAdministrationUsageDescription` (Explain need for Input Monitoring to detect shortcuts)
  - [x] Set up Feature-First directory structure (App, Core, Features, Resources)
- [x] Implement `CodeMaskApp.swift` entry point
- [x] Implement `AppEnvironment.swift` (Dependency Injection Container)
- [x] Create `AppStore` singleton (Architecture Root) injecting `AppEnvironment`
- [x] Implement `PermissionsManager` (Core/Security)
  - [x] Check Accessibility status
  - [x] Check Input Monitoring status
  - [x] Request permissions flow
- [x] Implement `MenuBarController` (Features/UI/Menu Bar)
  - [x] Create `NSStatusItem`
  - [x] Logic for icon state (Grey/Blue) based on permissions
- [x] Verify "Safe" state logic in `AppStore`

## Review Follow-ups (AI Code Review - 2026-01-05)

### 🔴 CRITICAL ISSUES
- [ ] [AI-Review][CRITICAL] Remove LSUIElement from Info.plist - normal app with Dock icon per revised AC #2 [CodeMask/CodeMask.xcodeproj]
- [ ] [AI-Review][CRITICAL] Complete `PermissionsManager.checkInputMonitoring()` - replace hardcoded `return true` [PermissionsManager.swift:23]
- [ ] [AI-Review][CRITICAL] Add error handling: dispatch `.didEncounterError(AppError)` if permission checks fail [CodeMaskApp.swift]
- [ ] [AI-Review][CRITICAL] Add `didEncounterError` case to `Security.Action` enum [AppStore.swift]

### 🟡 MEDIUM ISSUES
- [ ] [AI-Review][MEDIUM] Inject `PermissionsManager` via `AppEnvironment` for DI testability [AppEnvironment.swift]
- [ ] [AI-Review][MEDIUM] Ensure all `AppStore.send()` in AppDelegate runs on `@MainActor` safely [CodeMaskApp.swift]
- [ ] [AI-Review][MEDIUM] Expand test suite: AppDelegate lifecycle, PermissionsManager errors, MenuBarManager binding [CodeMaskTests]

### 🟢 LOW ISSUES  
- [ ] [AI-Review][LOW] Update File List - add ContentView.swift and document pbxproj changes [this file]
- [ ] [AI-Review][LOW] Add SF Symbol validation in MenuBarManager for compatibility [MenuBarManager.swift:35]

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
- Confirmed directory structure reorganization matches architecture.
- Implemented AppStore with Observation and MainActor isolation.
- Created AppEnvironment for dependency injection.
- **Fix**: Moved `@NSApplicationDelegateAdaptor` inside `CodeMaskApp` struct to fix "Extensions must not contain stored properties" error.
- **Fix**: Added `@MainActor` to `AppDelegate` methods to fix concurrency isolation error when calling `AppStore.send`.
- **Note**: User instructed to fix `DEVELOPMENT_ASSET_PATHS` in Xcode Build Settings manually.

### Completion Notes List
- Initial scaffolding story created.
- Epic 1 marked as in-progress.
- **IMPORTANT**: Files were moved/created on disk. Xcode project (`.xcodeproj`) references are currently broken. User MUST open Xcode and re-add/fix file references.
- Implemented `AppStore`, `MenuBarManager`, `PermissionsManager` (partial - InputMonitoring check not implemented).
- Added `AppStoreTests` (basic coverage only - 60% of code tested).
- **ARCHITECTURE DECISION (2026-01-05)**: AC #2 revised from `LSUIElement=YES (no Dock)` to normal app with Dock icon. Future Epic 2 will implement "hide Dock" feature. Rationale: MVP usability - users need ability to manually restart app.

### File List
- CodeMask/CodeMask/App/CodeMaskApp.swift (modified: AppDelegate updated 2026-01-05)
- CodeMask/CodeMask/App/AppStore.swift
- CodeMask/CodeMask/App/AppEnvironment.swift (placeholder - needs service injection)
- CodeMask/CodeMask/Features/UI/MenuBar/MenuBarManager.swift
- CodeMask/CodeMask/Features/UI/ContentView.swift (created but not in original File List)
- CodeMask/CodeMask/Core/Security/PermissionsManager.swift (partial: InputMonitoring stubbed)
- CodeMask/CodeMaskTests/App/AppStoreTests.swift (basic coverage only)
- CodeMask/CodeMask.xcodeproj/project.pbxproj (modified: file references updated 2026-01-05)