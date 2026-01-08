# Story 1.2: Global Hotkey Manager

Status: review

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

#### Completion Notes
- Verified that `Cmd+Opt+C` and `Cmd+Opt+V` trigger the correct actions in `AppStore`.
- Created unit tests in `HotkeysTests.swift` and verified they pass.
- Ensured proper cleanup of hotkeys on app termination.

### File List
- `CodeMask/Features/Hotkeys/Hotkeys.swift`
- `CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift`
- `CodeMaskTests/Features/Hotkeys/HotkeysTests.swift`
