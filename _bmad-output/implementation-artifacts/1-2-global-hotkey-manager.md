# Story 1.2: Global Hotkey Manager

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to use system-wide shortcuts (Cmd+Opt+C and Cmd+Opt+V),
so that I can trigger masking and restoration from any application without switching focus.

## Acceptance Criteria

1. **Global Interception**: Application intercepts `Cmd+Opt+C` and `Cmd+Opt+V` events system-wide.
2. **Background Operation**: Shortcuts work regardless of the active application (Xcode, Browser, Slack) while CodeMask is running in menu bar.
3. **Action Dispatch**: Triggering a shortcut dispatches the corresponding event (`.didTriggerMasking` or `.didTriggerRestoration`) to the `AppStore`.
4. **Conflict Handling**: Application does not crash or block system if shortcuts are already registered by another app (fail gracefully/log).
5. **Zero Dependencies**: Implementation uses native macOS APIs (Carbon/HIToolbox or CGEvent) without external libraries like `HotKey` or `Magnet`.

## Tasks / Subtasks

- [ ] Create Feature Module `Features/Hotkeys`
  - [ ] Create `Hotkeys.swift` (Namespace: State/Action)
  - [ ] Create `GlobalHotkeyManager.swift` (Logic)
- [ ] Implement Native Hotkey Registration
  - [ ] Define `Hotkey` struct/enum (Key + Modifiers)
  - [ ] Implement registration logic using `Carbon` (`RegisterEventHotKey`) OR `CGEvent` tap (Decision: Carbon preferred for specific hotkeys)
  - [ ] Implement event handler callback
- [ ] Integrate with `AppStore`
  - [ ] Add `Hotkeys` module to `AppEnvironment`
  - [ ] Add `Hotkeys.State` to `AppState`
  - [ ] Handle `Hotkeys.Action` in `AppReducer` (logging for now, masking logic in future stories)
- [ ] Error Handling & Permissions
  - [ ] Verify Input Monitoring permission before registering
  - [ ] Handle registration failures
- [ ] Testing
  - [ ] Unit test `GlobalHotkeyManager` (Mocking system APIs if possible, or isolating logic)
  - [ ] Integration test: Verify Store receives actions

## Dev Notes

### Technical Requirements

- **API Choice**: Use `Carbon.framework` (specifically `RegisterEventHotKey`) for robust global hotkey handling. It is the standard native way to handle global shortcuts without "Input Monitoring" heavy-handedness (though we have that permission).
- **Concurrency**: Hotkey callbacks often come on a special thread or main thread loop. Ensure generic `Userinfo` pointer handling is safe and actions are dispatched to `AppStore` on `@MainActor`.
- **State Management**:
  - `Hotkeys.State`: might track `isMaskingShortcutRegistered`, `isRestorationShortcutRegistered`.
  - `Hotkeys.Action`: `.didTriggerMasking`, `.didTriggerRestoration`, `.didFailToRegister(Error)`.

### Architecture Compliance

- **Namespace**: `CodeMask/Features/Hotkeys/`
- **Isolation**: `GlobalHotkeyManager` should be a service injected into `AppEnvironment`.
- **DI**: Define `HotkeyServiceProtocol` to allow mocking in tests.
- **Naming**: Actions must be Events: `.didTriggerMasking`, NOT `.performMasking`.

### Developer Guardrails (From Story 1.1 Learnings)

- **Resource Management**: If using `CGEvent` or `Carbon` refs, ensure proper cleanup/unregistration on app termination (though OS handles process death, good hygiene is required).
- **MainActor Safety**: Dispatching to `AppStore` MUST be on MainActor. Use `Task { @MainActor in store.send(...) }` if callback is on background thread.
- **Error Visibility**: Do not fail silently. If hotkeys fail to register (e.g. taken by another app), log it and update State so UI (future) can warn user.

### Project Structure Notes

- New Directory: `CodeMask/Features/Hotkeys/`
- Files:
  - `Hotkeys.swift` (Namespace)
  - `GlobalHotkeyManager.swift` (Implementation)

### References

- [Architecture: Project Structure](_bmad-output/architecture.md#project-structure--boundaries)
- [Epic 1.2 Criteria](_bmad-output/epics.md#story-12-global-hotkey-manager)

## Dev Agent Record

### Agent Model Used
Gemini Pro 1.5 (Simulated)

### Debug Log References

### Completion Notes List

### File List
