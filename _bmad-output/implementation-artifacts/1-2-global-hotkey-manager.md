# Story 1.2: Global Hotkey Manager

Status: done

<!-- Note: Validation COMPLETED. Improvements applied for technical accuracy and LLM optimization. -->

## Story

As a user,
I want to use system-wide shortcuts (Cmd+Opt+C and Cmd+Opt+V),
so that I can trigger masking and restoration from any application without switching focus.

## Acceptance Criteria

1. **Global Interception**: Application intercepts `Cmd+Opt+C` and `Cmd+Opt+V` events system-wide.
2. **Background Operation**: Shortcuts work regardless of the active application (Xcode, Browser, Slack).
3. **Action Dispatch**: Triggering a shortcut dispatches events (`.didTriggerMasking`, `.didTriggerRestoration`) to the `AppStore`.
4. **Conflict Handling**: Fail gracefully if shortcuts are already registered (taken by another app).
5. **Zero Dependencies**: Implementation uses native `Carbon` (`RegisterEventHotKey`) without external libraries.

## Senior Developer Review (AI)

**Status**: ✅ **APPROVED**
**Review Date**: 2026-01-08
**Reviewer**: Amelia (Senior Developer Agent)

### Action Items
- [x] Fix event handler installed multiple times (Issue 1) - 🔴 CRITICAL
- [x] Fix potential use-after-free in handler callback (Issue 2) - 🔴 CRITICAL
- [x] Capture and propagate specific error codes on registration failure (Issue 3) - 🔴 CRITICAL
- [x] Synchronize `Hotkeys.State` with registration results (Issue 4) - 🔴 CRITICAL
- [x] Implement reducer logic for hotkey trigger actions (Issue 5) - 🔴 CRITICAL
- [x] Add explicit handler cleanup in `deinit` (Issue 6) - 🟡 HIGH
- [x] Implement comprehensive logging (Issue 7) - 🟡 HIGH
- [x] Add tests for failure paths and triggers (Issue 8) - 🟡 HIGH
- [x] Add race condition protection for registration (Issue 9) - 🟡 HIGH
- [x] Add documentation and clean up magic numbers (Issue 10, 11) - 🟠 MEDIUM

## Tasks / Subtasks

- [x] **Feature Scaffolding**
  - [x] Create `CodeMask/Features/Hotkeys/Hotkeys.swift` (Namespace)
    - Define `enum Hotkeys { struct State... enum Action... }`
    - Action cases: `.didTriggerMasking`, `.didTriggerRestoration`, `.didFailToRegister(AppError)`
  - [x] Create `CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift` (Service)
- [x] **Carbon Hotkey Implementation**
  - [x] Define `HotkeyID` constants (Masking vs Restoration)
  - [x] Implement `registerHotkeys()` using `RegisterEventHotKey`
  - [x] Implement `unregisterHotkeys()` to clean up `EventHotKeyRef`
  - [x] Implement C-style callback bridge to `GlobalHotkeyManager` instance
- [x] **Integration & Safety**
  - [x] Add `HotkeyServiceProtocol` to `AppEnvironment`
  - [x] Dispatch actions to `AppStore` on `@MainActor`
  - [x] **Permission Note**: `Carbon` hotkeys do NOT require Accessibility/Input Monitoring. Do NOT block registration on these permissions.
- [x] **Cleanup & Lifecycle**
  - [x] Call `unregisterHotkeys()` on `deinit` or app termination to prevent resource leaks.
- [x] **Testing & Verification**
  - [x] Unit test `GlobalHotkeyManager` logic (mocking the store dispatch)
  - [x] Manual test: Verify HUD (if implemented) or Logs trigger on `Cmd+Opt+C/V`

### Review Follow-ups (AI)
- [x] [AI-Review] Fix memory leak: Ensure event handler is installed only once.
- [x] [AI-Review] Fix memory safety: Ensure strong reference for callback refCon.
- [x] [AI-Review] Enhance error handling: Capture Carbon error codes and map to `AppError`.
- [x] [AI-Review] Sync State: Update `isMaskingRegistered` and `isRestorationRegistered`.
- [x] [AI-Review] Complete Reducer: Handle `.didTriggerMasking` and `.didTriggerRestoration`.
- [x] [AI-Review] Resource Cleanup: Explicitly call `RemoveEventHandler` in `deinit`.
- [x] [AI-Review] Observability: Add logging for registration and triggers.
- [x] [AI-Review] Quality: Add tests for failure scenarios and trigger simulation.
- [x] [AI-Review] Concurrency: Add locking for hotkey registration.

## Dev Notes

### Technical Directives

- **API Choice**: Use `Carbon.framework`. It is the native macOS way to handle global shortcuts without requiring intrusive user permissions.
- **C-Interop Safety**: Use `Unmanaged.passUnretained(self).toOpaque()` to pass the manager instance as `refCon`, and `Unmanaged<GlobalHotkeyManager>.fromOpaque(refCon).takeUnretainedValue()` inside the C callback to regain context.
- **Carbon Signature**: Define a unique 4-char signature (e.g., `'CMSK'`) for `EventHotKeyID.signature` to avoid collisions with other apps using the same ID integers.
- **Concurrency**: Ensure the C-callback dispatches to the `AppStore` using `Task { @MainActor in ... }`.
- **Error Propagation**: If registration fails (e.g., `eventHotKeyAlreadyRegisteredErr`), dispatch `.didFailToRegister(AppError)` so the central Store can handle visibility.

### Architecture Compliance

- **Namespace**: `CodeMask/Features/Hotkeys/`
- **DI Pattern**: Inject `GlobalHotkeyManager` as a dependency in `AppEnvironment`.
- **Action Naming**: Use event-based naming: `.didTriggerMasking`.

### Developer Guardrails

- **Resource Hygiene**: You MUST unregister hotkeys when the manager is disposed.
- **Permission Clarity**: `Story 1.1` permissions are for *Guardian Mode*. This story (Hotkeys) should function even if the user has not yet granted Accessibility/Input Monitoring.

### Dev Agent Record

#### Implementation Plan
- Implemented `Hotkeys` namespace with `State` and `Action`.
- Implemented `GlobalHotkeyManager` using `Carbon`'s `RegisterEventHotKey` and `InstallEventHandler`.
- Integrated `GlobalHotkeyManager` into `AppEnvironment` and `AppStore`.
- Added `registerHotkeys()` and `unregisterHotkeys()` calls to `AppDelegate`.
- Fixed Swift 6 concurrency issues in `AppDelegateTests.swift`.
- **Review Fixes**: 
    - Added `eventHandlerRef` to prevent multiple installations.
    - Added `NSLock` for thread-safe registration.
    - Improved error handling with specific Carbon error codes.
    - Synchronized `Hotkeys.State` with registration success/failure.
    - Completed `AppStore` reducer to track last triggered hotkey and time.
    - Added explicit `RemoveEventHandler` in `deinit`.
    - Added comprehensive logging using `os.Logger`.
    - Expanded unit tests to cover state sync and trigger tracking.

#### Completion Notes
- Verified that `Cmd+Opt+C` and `Cmd+Opt+V` trigger the correct actions in `AppStore`.
- Created unit tests in `HotkeysTests.swift` and verified they pass.
- Ensured proper cleanup of hotkeys on app termination.
- All code review findings addressed and verified.

### File List
- `CodeMask/Features/Hotkeys/Hotkeys.swift`
- `CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift`
- `CodeMaskTests/Features/Hotkeys/HotkeysTests.swift`
- `CodeMask/CodeMask/App/AppStore.swift`
