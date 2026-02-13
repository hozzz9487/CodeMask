# Story 2.5: Browser Guard & Alert HUD

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-prd/validate-story for quality check before dev. -->

## Story

As a "Guardian" user,
I want to be warned if I'm about to paste unmasked secrets into a browser,
So that I can prevent accidental data leaks to web-based AI tools.

## Acceptance Criteria

1. **Given** the clipboard contains unmasked sensitive patterns (`session.hasSecrets == true`)
   **When** I switch focus to a web browser window (`guardian.isBrowserFocused == true`)
   **Then** a Red "Danger" HUD should appear immediately
   **And** it should warn "Unmasked Secrets Detected"
   **And** the Menu Bar icon should switch to the Warning state (handled by Story 2.1/2.4 logic).

2. **Given** the Danger HUD is visible
   **When** I switch away from the browser OR mask the secrets
   **Then** the HUD should vanish immediately.

3. **Given** the HUD system
   **When** displaying the "Danger" state
   **Then** it must NOT steal keyboard focus from the browser (NSPanel `.nonactivatingPanel`)
   **And** it should appear centered at the top/bottom (per UX design)
   **And** it should use the "Pill" design with `systemRed` and an alert icon.

4. **Given** the system architecture
   **When** trigger conditions are met
   **Then** the `HUD` state visibility must be driven by the centralized `AppStore`
   **And** the `HUDManager` must observe the Store, not the Detector directly.

## Dev Notes

### Existing Implementation Reuse (Current Codebase)

-   **HUD Namespace Exists**: `CodeMask/CodeMask/Features/HUD/HUD.swift`
-   **HUD Window Manager Exists**: `CodeMask/CodeMask/Features/HUD/HUDManager.swift`
-   **HUD View Exists**: `CodeMask/CodeMask/Features/HUD/HUDView.swift`
-   **HUD Reducer Exists in AppStore**: `CodeMask/CodeMask/App/AppStore.swift` (`reduce(hud:)`)
-   **Guardian Integration Exists**: `CodeMask/CodeMask/App/Reducers/AppStore+Guardian.swift` (`evaluateDangerState()`)

### Architecture & Design Patterns

-   **State Driven UI**: HUD visibility is strictly derived from store state.
    -   Do NOT trigger `NSPanel` methods from random feature code.
    -   `HUDManager` observes `store.hud`.
-   **Unidirectional Flow**:
    -   `AppStore+Guardian.swift` computes `session.isDanger`.
    -   HUD actions are dispatched by Store-side mapping logic (danger on/off -> hud show/hide).
    -   `HUDManager` only renders from `HUD.State`.
-   **Do Not Rebuild Existing Components**:
    -   Do NOT create duplicate `HUD` namespace files under `Features/UI/HUD`.
    -   Do NOT create `AppStore+HUD.swift` unless team decides to refactor reducer split later.
    -   Do NOT re-implement or duplicate Menu Bar state rendering logic from Story 2.1/2.4.

### Danger State Mapping (Single Source of Truth)

| `guardian.isBrowserFocused` | `session.hasSecrets` | `session.isDanger` | HUD Action |
|---|---|---|---|
| false | false | false | `send(.hud(.hide))` |
| false | true | false | `send(.hud(.hide))` |
| true | false | false | `send(.hud(.hide))` |
| true | true | true | `send(.hud(.show(message: "Unmasked Secrets Detected", type: .error)))` |

**Rule:** Danger HUD must remain visible while `session.isDanger == true`; do not apply transient auto-hide timer to this state.

### Technical Constraints (Project Context Compliance)

-   **Focus Integrity**: The `NSPanel` must use `.styleMask = [.borderless, .nonactivatingPanel]`.
-   **VRAM Protection**: Before hiding/closing, clear the SwiftUI view content to `EmptyView()` or purely transparent to avoid ghosting/residue in Window Server.
-   **Appearance**: Use `NSVisualEffectView` with `.hudWindow` material backing.
-   **Thread Safety**: `HUDManager` must be `@MainActor`.

### Previous Story Intelligence (Related to Story 2.4/2.1)

-   **Story 2.4** implemented `guardian.isBrowserFocused` and `session.isDanger`.
-   **Story 2.1** implemented `MenuBarManager` observing `securityStatus`.
-   **Integration Point**:
    -   `session.isDanger` is the source of truth.
    -   Map danger transitions to existing HUD API (`.hud(.show(message:type:))` / `.hud(.hide)`), using `.error` for danger visual state.
    -   Danger HUD must be persistent while `isDanger == true`; it should not auto-hide on timer.

### File Structure Requirements

-   `CodeMask/CodeMask/Features/HUD/HUD.swift` (Existing namespace; extend if needed)
-   `CodeMask/CodeMask/Features/HUD/HUDManager.swift` (Existing window logic; adjust behavior if needed)
-   `CodeMask/CodeMask/Features/HUD/HUDView.swift` (Existing SwiftUI view; ensure danger style matches UX)
-   `CodeMask/CodeMask/App/AppStore.swift` (Existing HUD reducer and action handling)
-   `CodeMask/CodeMask/App/Reducers/AppStore+Guardian.swift` (Existing danger evaluation)

### UX Specifications (from UX Doc)

-   **Shape**: Capsule (Pill).
-   **Color**: `systemRed` for Danger.
-   **Icon**: SF Symbol `exclamationmark.shield.fill`.
-   **Animation**: "Snappy, high-velocity Slide In".
-   **Position**: Bottom center or Top center (Default to Bottom for non-obstructive).

### Accessibility & Environment Requirements

-   **Reduce Motion**: Respect `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`; disable slide animation when enabled.
-   **VoiceOver**: Announce danger HUD state (e.g., "CodeMask Status: Unmasked Secrets Detected").
-   **Color Independence**: Danger state must include icon + text; never rely on red color alone.
-   **Multi-Monitor**: Render HUD on active display (display with current keyboard/mouse focus).

## Tasks / Subtasks

- [ ] **Task 1: Align Existing HUD Model to Danger Requirements** (AC: 1, 2, 4)
    -   [ ] Reuse `Features/HUD/HUD.swift` (no duplicate namespace files).
    -   [ ] Keep current `HUD.Action.show(message:type:)` API, using `.error` for danger.
    -   [ ] If needed, add minimal state to support persistent-vs-transient behavior without breaking existing success/info HUD flows.

- [ ] **Task 2: Update Existing HUD Reducer Behavior** (AC: 2, 4)
    -   [ ] Reuse `AppStore.swift` `reduce(hud:)`.
    -   [ ] Ensure danger HUD does not auto-hide while `session.isDanger == true`.
    -   [ ] Preserve current auto-hide behavior for transient success/info feedback.

- [ ] **Task 3: Validate Existing HUDView for Danger UX** (AC: 3)
    -   [ ] Reuse `Features/HUD/HUDView.swift`.
    -   [ ] Ensure danger icon/text/color align with UX spec (`exclamationmark.shield.fill`, red semantics).
    -   [ ] Keep Pill shape and non-intrusive visual hierarchy.
    -   [ ] Ensure text/icon alone communicate danger (accessible without color cues).

- [ ] **Task 4: Validate Existing HUDManager Window Behavior** (AC: 3)
    -   [ ] Reuse `Features/HUD/HUDManager.swift` (no new controller file).
    -   [ ] Keep `NSPanel` transparent, borderless, non-activating.
    -   [ ] Ensure hide path clears content before closing.
    -   [ ] Ensure active-display placement logic works for multi-monitor setups.
    -   [ ] Gate motion effects by system Reduce Motion setting.

- [ ] **Task 5: Integrate with Guardian Logic** (AC: 1, 2)
    -   [ ] Use existing `AppStore+Guardian.swift` danger evaluation flow.
    -   [ ] When browser is focused AND `session.hasSecrets == true`:
        -   `send(.hud(.show(message: "Unmasked Secrets Detected", type: .error)))` (persistent while danger is true).
    -   [ ] When `didDeactivate` OR secrets cleared:
        -   `send(.hud(.hide))`.

- [ ] **Task 6: Unit Testing**
    -   [ ] Test danger transition mapping (`isDanger false -> true` shows danger HUD).
    -   [ ] Test danger clear transition (`isDanger true -> false`) hides HUD immediately.
    -   [ ] Test transient HUD behavior remains intact for existing masking/restoration flows.
    -   [ ] Test no regression in Menu Bar warning behavior (still driven by `session.isDanger`).
    -   [ ] Test danger HUD content is deterministic: exact message + error type.

- [ ] **Task 7: Latency Validation (Per Story 2.0 Findings)**
    -   [ ] Measure end-to-end latency from "Browser Focus Event" to "HUD Visible".
    -   [ ] Ensure total response time is < 50ms.
    -   [ ] Verify immediate dismissal when switching away.

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
