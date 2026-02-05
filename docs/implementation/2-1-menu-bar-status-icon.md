# Story 2.1: Menu Bar Status Icon

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to know the security status of my session at a glance,
so that I can verify if I have sensitive data stored in memory or if there are potential risks.

## Acceptance Criteria

1. **Given** the application is running
   **When** the session map is empty (No secrets stored)
   **Then** the Menu Bar icon should be **Safe (Grey)**.

2. **Given** the application is running
   **When** the session map contains secure data (Secrets stored in RAM)
   **Then** the Menu Bar icon should be **Secured (Blue)**.

3. **Given** the application is running
   **When** a "Danger" state is detected (e.g., Browser focused + Unmasked secrets)
   **Then** the Menu Bar icon should be **Warning (Red)**.
   *(Note: The logic to triggering "Danger" comes in later stories (2.4/2.5), but this Story must implement the **visual state capability** to display Red when told).*

## Technical Requirements

### Architecture & Pattern Compliance
- **Framework**: Use **AppKit (`NSStatusBar`, `NSStatusItem`)** as specified in `architecture.md` (Not SwiftUI `MenuBarExtra` if it limits programmatic icon manipulation or legacy support, though `MenuBarExtra` is acceptable if it meets all UI requiremens. Architecture explicitly mentions "AppKit... NSStatusBar").
- **State Observation**: The Menu Bar component (e.g., `MenuBarManager`) must observe `AppStore.state` (specifically a computed `securityStatus` property).
- **Unidirectional Flow**: The Menu Bar is a **View** (projection of state). It must **NOT** contain business logic. It simply reflects the current store state.
- **Namespace**: Ensure code resides in `CodeMask/Features/UI/Menu Bar/`.

### UI/UX Specifications
- **Iconography (SF Symbols)**:
  - **Idle (Grey)**: `shield` (SymbolName) / `systemGray` (Color)
  - **Secured (Blue)**: `lock.shield.fill` / `systemBlue`
  - **Warning (Red)**: `exclamationmark.shield.fill` / `systemRed`
- **Accessibility**: Ensure the `NSStatusItem.button` has a helpful `accessibilityLabel` (e.g., "CodeMask: Secured", "CodeMask: Idle").

## Tasks / Subtasks

- [ ] **Task 1: Define Security State API**
  - [ ] Update `AppState` (or `Session.State`) to expose a clear `SecurityStatus` enum (`.idle`, `.secured`, `.warning`).
  - [ ] Add computed properties or selectors to derive this state from `SessionMap.isEmpty` and future `Guardian.status`.

- [ ] **Task 2: Implement MenuBarManager**
  - [ ] Create `class MenuBarManager` (or `Controller`) that initializes `NSStatusBar.system.statusItem`.
  - [ ] Implement the `updateIcon(for status: SecurityStatus)` logic.
  - [ ] ensure precise SF Symbol rendering with correct tint colors using `NSImage.symbolConfiguration`.

- [ ] **Task 3: Connect to AppStore**
  - [ ] Subscribe `MenuBarManager` to `AppStore` state changes.
  - [ ] Verify state-to-icon updates are driven solely by the store.

- [ ] **Task 4: Unit Testing**
  - [ ] Write logic tests (if logic exists in a ViewModel/Presenter).
  - [ ] Verify `SecurityStatus` derivation logic (e.g., "If map has items -> Secured").

## Dev Notes

- **AppKit vs SwiftUI**: While SwiftUI has `MenuBarExtra`, `NSStatusItem` is often more robust for utility apps needing precise control over button states or popovers. Stick to **AppKit** wrappers for the Status Item itself per architecture docs.
- **Asset Handling**: Provide a fallback if SF Symbols fail (unlikely on macOS 14+), but strictly use SFSymbols as primary.
- **Thread Safety**: Ensure all UI updates to `NSStatusItem` happen on **MainActor**.

### Project Structure Notes

- **File Location**: `CodeMask/Features/UI/Menu Bar/`
- **Test Location**: `CodeMaskTests/Features/UI/Menu Bar/`

### References

- [Source: _bmad-output/epics.md#Story 2.1]
- [Source: _bmad-output/architecture.md#Frontend Architecture]
- [Source: _bmad-output/ux-design-specification.md#Visual Design Foundation]
- [Apple Docs: NSStatusBar](https://developer.apple.com/documentation/appkit/nsstatusbar)
- [Apple Docs: SF Symbols](https://developer.apple.com/sf-symbols/)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
