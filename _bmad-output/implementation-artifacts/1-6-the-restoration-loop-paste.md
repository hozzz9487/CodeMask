# Story 1.6: The Restoration Loop (Paste)

Status: ready-for-dev

<!-- Note: Validation optional but recommended. Run validate-create-story. -->

## Story

As a user,
I want the "Re-hydration Paste" action to restore my original secrets into AI-generated code,
So that I don't have to manually find and replace placeholders, and strict binary fidelity is guaranteed.

## Acceptance Criteria

### 1. The Core Loop (Logic & Concurrency)

*   **Trigger**: Initiated by `.didTriggerRestorationShortcut` (Default: `Cmd+Ctrl+V`, aligning with recent project changes).
*   **Concurrency Pattern (CRITICAL)**:
    *   **Conflated Task**: Similar to the Masking Loop, the restoration process MUST run in a **detached cancellable Task** to handle rapid triggers safely.
    *   **Non-Blocking**: All processing (Regex -> Session Lookup -> Paste) MUST occur off the Main Actor.
*   **Logic Steps**:
    1.  **Read**: Get current string from `PasteboardService`. Guard for empty.
    2.  **Scan**: Use `RegexEngine` to identify all `{{CM_TOKEN_...}}` placeholders.
    3.  **Lookup**: Batch resolve tokens against `SessionActor`.
        *   **Hit**: Retrieve original secret.
        *   **Miss**: Return explicit error marker `>>MISSING_SECRET<<`.
    4.  **Reconstruct**: Replace placeholders with resolved values (or error markers) to create the `restoredContent`.
    5.  **Action Branching**:
        *   **If Restoration Occurred** (tokens found & replaced):
            *   **Paste**: Attempt to inject `restoredContent` into the active application.
            *   **Feedback**: Dispatch `.restorationSequenceCompleted(.success)`.
        *   **If No Tokens Found**:
            *   **Passthrough**: Do NOT modify clipboard. Do NOT trigger paste (let system handle normal paste? OR simulate paste of original content? *Decision: If specific shortcut is used, we expect a paste. If we can't restore, we should probably just paste what's there or inform user. Current decision: If no tokens, simulate paste of current content to maintain "Paste" behavior of the shortcut, or show "No Tokens" HUD? PRD says "Trigger Re-hydration Paste". If no tokens, it's just a paste. Let's explicit: Simulate standard paste.*) -> *Refinement: If the global shortcut effectively "steals" the paste command, we must ensure it pastes. However, if it's a dedicated "Magic Paste" separate from "Cmd+V", we might only want to act if tokens exist. Given it's a separate Global Hotkey, if no tokens are found, we should provide feedback "No Tokens Detected" and optionally paste raw.*
            *   **Refined Logic**: If no tokens, show "No Tokens" HUD (Grey) and do nothing (User can use standard Cmd+V). This avoids unexpected behavior.

### 2. The Injection Mechanism (Paste)

*   **Primary Method**: Simulated Keystroke (`Cmd+V`) via `KeyboardService`.
    *   **Pre-requisite**: The `restoredContent` must be placed on the `NSPasteboard` *temporarily* for the paste to work.
    *   **Security Hygiene**:
        1.  Save current clipboard state (masked).
        2.  Write `restoredContent` (unmasked secrets!) to clipboard.
        3.  Trigger `Cmd+V` (Simulated).
        4.  **Wait** for paste to complete (short delay ~200ms or check change count?).
        5.  **Restore** clipboard to "Safe" masked state immediately after paste.
    *   **Why?**: Direct accessibility injection (`AXUIElement`) is often flaky with modern sandboxed apps (VS Code, Xcode). Clipboard-shuffling is the standard robust pattern for clipboard managers.
*   **Fallback**: If paste simulation fails or permissions missing, leave `restoredContent` on clipboard (temporarily?) and show "Ready to Paste" HUD. *Actually, for security, we prefer NOT to leave secrets on clipboard. Better fallback: "Paste Failed - Copied to Clipboard (10s)".*

### 3. Fail-Safe Protocol

*   **Explicit Error Tokens**: Any `{{CM_TOKEN_...}}` not found in `SessionActor` MUST be replaced with `>>MISSING_SECRET<<`.
*   **Atomic Fidelity**: Partial restoration is allowed, BUT missing secrets must be visibly broken to prevent silent failures (e.g., compiling with a missing key).

### 4. Feedback System

*   **Visual**:
    *   Success: HUD "Restored" (Green).
    *   Partial/Error: HUD "Missing Secrets" (Red) + Haptic Warning.
    *   No Tokens: HUD "No Tokens" (Grey).
*   **Audio/Haptic**:
    *   Success: "Tink" + Tap.
    *   Error: "Thump" + Alignment.

## Tasks

- [ ] **Service Enhancements**
    - [ ] Update `KeyboardService` to support `simulatePaste()` (Cmd+V).
    - [ ] Update `SessionActor` to support `resolve(tokens: [String]) -> [String: String?]` batch lookup.
    - [ ] Update `RegexEngine` to support `replace(content: String, mapping: [String: String])`.
- [ ] **Restoration Logic (Reducer)**
    - [ ] Handle `.didTriggerRestorationShortcut`:
        - [ ] Run in detached task.
        - [ ] Execute Scan -> Lookup -> Reconstruct logic.
        - [ ] Execute "Secure Paste Dance" (Save -> Write Secret -> Paste -> Restore Safe).
- [ ] **Feedback Wiring**
    - [ ] Wire up `.restorationSequenceCompleted` to HUD/Audio/Haptics.
- [ ] **Tests**
    - [ ] `RestorationLoopTests.swift`:
        - [ ] Test full hit (all tokens found).
        - [ ] Test partial miss (insert `>>MISSING_SECRET<<`).
        - [ ] Test "Secure Paste Dance" sequence (verify clipboard is restored to safe state).

## Dev Notes

### Architecture Compliance

*   **Secure Paste Dance**: This is a critical pattern. We must NEVER leave unmasked secrets on the clipboard longer than the milliseconds required to paste.
    *   *Risk*: If app crashes during the "Dance", secrets might remain.
    *   *Mitigation*: Use `defer { restoreClipboard() }` in the Task to ensure cleanup happens even on cancellation or error.
*   **KeyboardService**: Ensure `CGEvent` usage handles the "Command" flag correctly. Note that `Cmd+Ctrl+V` trigger might physically have keys held down; adding a small delay or ensuring modifier flags are clean before simulating `Cmd+V` is often necessary to avoid `Cmd+Ctrl+V` + `V` conflicts.

### Previous Story Intelligence (Story 1.5)

*   **Conflated Task**: Re-use the exact same cancellation pattern used in `MaskingLoop`.
*   **Services**: `PasteboardService`, `HapticService`, `AudioService` are ready. `KeyboardService` was started in 1.5 (per git log).

### Technical Requirements

*   **Token Format**: `{{CM_TOKEN_UUID}}`. Regex must match this robustly.
*   **Performance**: Restoration + Paste must feel instant.

### References

*   [Source: Core/Services/KeyboardService.swift] - Check existing implementation.
*   [Source: Features/Session/SessionActor.swift] - Check storage structure.

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
