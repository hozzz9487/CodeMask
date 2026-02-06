# Story 2.1: Menu Bar Status Icon

Status: review

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
   **And** the icon should **flash Red** (brief pulse) to draw attention.
   *(Note: The logic to triggering "Danger" comes in later stories (2.4/2.5), but this Story must implement the **visual state capability** to display Red when told).*

4. **Given** the application is running
   **When** security status cannot be determined (e.g., permissions missing, initialization, or store state unknown)
   **Then** the Menu Bar icon should show **Unknown (Grey)** distinct from Safe/Idle state if possible.

## Technical Requirements

### Architecture & Pattern Compliance
- **Framework**: Use **AppKit (`NSStatusBar`, `NSStatusItem`)** as specified in `architecture.md` (Not SwiftUI `MenuBarExtra` if it limits programmatic icon manipulation or legacy support, though `MenuBarExtra` is acceptable if it meets all UI requiremens. Architecture explicitly mentions "AppKit... NSStatusBar").
- **State Derivation**: `SecurityStatus` must be derived in `AppState` / reducer layer (single source of truth). `MenuBarManager` only renders and must not contain business logic.
- **State Observation**: The Menu Bar component (e.g., `MenuBarManager`) must observe `AppStore.state` (specifically a computed `securityStatus` property).
- **Unidirectional Flow**: The Menu Bar is a **View** (projection of state). It must **NOT** contain business logic. It simply reflects the current store state.
- **Namespace**: Ensure code resides in `CodeMask/Features/UI/Menu Bar/`.

### UI/UX Specifications
- **Iconography (SF Symbols)**:
  - **Idle (Grey)**: `shield` (SymbolName) / `systemGray` (Color)
  - **Secured (Blue)**: `lock.shield.fill` / `systemBlue`
  - **Warning (Red)**: `exclamationmark.shield.fill` / `systemRed`
- **Unknown (Grey)**: Use `questionmark.shield` / `systemGray` (or alternative neutral glyph) to differentiate from Idle if feasible.
- **Accessibility**: Ensure the `NSStatusItem.button` has a helpful `accessibilityLabel` (e.g., "CodeMask: Secured", "CodeMask: Idle").
- **Template/Tint**: Ensure status images are compatible with system appearance. Prefer `NSImage.isTemplate = true` with `contentTintColor` for explicit state colors, or document why a non-template image is required.
- **State Priority**: Warning > Secured > Idle/Unknown. Unknown used when required data unavailable.

## Tasks / Subtasks

- [x] **Task 1: Define Security State API**
  - [x] Update `AppState` (or `Session.State`) to expose a clear `SecurityStatus` enum (`.idle`, `.secured`, `.warning`).
  - [x] Add computed properties or selectors to derive this state from `SessionMap.isEmpty` and future `Guardian.status`.

- [x] **Task 2: Implement MenuBarManager**
  - [x] Create `class MenuBarManager` (or `Controller`) that initializes `NSStatusBar.system.statusItem`.
  - [x] Implement the `updateIcon(for status: SecurityStatus)` logic.
  - [x] ensure precise SF Symbol rendering with correct tint colors using `NSImage.symbolConfiguration`.
  - [x] Implement a brief Warning flash (e.g., 2-3 pulses, ~150ms each) without infinite animation.
  - [x] Avoid redundant updates if status is unchanged (simple guard or debounce).

- [x] **Task 3: Connect to AppStore**
  - [x] Subscribe `MenuBarManager` to `AppStore` state changes.
  - [x] Verify state-to-icon updates are driven solely by the store.

- [x] **Task 4: Unit Testing**
  - [x] Write logic tests (if logic exists in a ViewModel/Presenter).
  - [x] Verify `SecurityStatus` derivation logic (e.g., "If map has items -> Secured").
  - [x] Add unit tests for icon mapping (status -> symbol + tint).
  - [x] Consider protocol-wrapping `NSStatusItem` for testability.

## Dev Notes

- **AppKit vs SwiftUI**: While SwiftUI has `MenuBarExtra`, `NSStatusItem` is often more robust for utility apps needing precise control over button states or popovers. Stick to **AppKit** wrappers for the Status Item itself per architecture docs.
- **Asset Handling**: Provide a fallback if SF Symbols fail (unlikely on macOS 14+), but strictly use SFSymbols as primary.
- **Thread Safety**: Ensure all UI updates to `NSStatusItem` happen on **MainActor**.
- **State Mapping**: Keep `SecurityStatus` mapping as a pure function for easy testing and determinism.

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

- Implemented `Session.SecurityStatus` enum and `securityStatus` computed property.
- Created `MenuBarManager` using AppKit `NSStatusBar`.
- Implemented icon updates based on security status using SF Symbols.
- Added `triggerWarningFlash` for visual feedback in warning state.
- Integrated `MenuBarManager` into `CodeMaskApp` and `AppDelegate`.
- Added unit tests for `MenuBarManager` logic and `Session.State` derivation.
- Verified all new and existing unit tests pass.

### File List

- CodeMask/CodeMask/Features/Session/Session.swift
- CodeMask/CodeMask/Features/UI/MenuBar/MenuBarManager.swift
- CodeMask/CodeMask/App/CodeMaskApp.swift
- CodeMask/CodeMaskTests/Features/UI/MenuBar/MenuBarManagerTests.swift
- CodeMask/CodeMaskTests/Features/Session/SessionStateTests.swift
