# Story 1.2: Global Hotkey Manager

Status: ready-for-dev

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

- [ ] **Feature Scaffolding**
  - [ ] Create `CodeMask/Features/Hotkeys/Hotkeys.swift` (Namespace)
    - Define `enum Hotkeys { struct State... enum Action... }`
    - Action cases: `.didTriggerMasking`, `.didTriggerRestoration`, `.didFailToRegister(AppError)`
  - [ ] Create `CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift` (Service)
- [ ] **Carbon Hotkey Implementation**
  - [ ] Define `HotkeyID` constants (Masking vs Restoration)
  - [ ] Implement `registerHotkeys()` using `RegisterEventHotKey`
  - [ ] Implement `unregisterHotkeys()` to clean up `EventHotKeyRef`
  - [ ] Implement C-style callback bridge to `GlobalHotkeyManager` instance
- [ ] **Integration & Safety**
  - [ ] Add `HotkeyServiceProtocol` to `AppEnvironment`
  - [ ] Dispatch actions to `AppStore` on `@MainActor`
  - [ ] **Permission Note**: `Carbon` hotkeys do NOT require Accessibility/Input Monitoring. Do NOT block registration on these permissions.
- [ ] **Cleanup & Lifecycle**
  - [ ] Call `unregisterHotkeys()` on `deinit` or app termination to prevent resource leaks.
- [ ] **Testing & Verification**
  - [ ] Unit test `GlobalHotkeyManager` logic (mocking the store dispatch)
  - [ ] Manual test: Verify HUD (if implemented) or Logs trigger on `Cmd+Opt+C/V`

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

### File List
- `CodeMask/Features/Hotkeys/Hotkeys.swift`
- `CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift`
