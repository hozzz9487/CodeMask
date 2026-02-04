# Story 1.6: The Restoration Loop (Paste)

Status: review

## Story

As a user,
I want the "Re-hydration Paste" action to restore my original secrets into AI-generated code,
So that I don't have to manually find and replace placeholders, and strict binary fidelity is guaranteed.

## Acceptance Criteria

### 1. The Core Loop (Logic & Concurrency)

*   **Trigger**: Initiated by `.didTriggerRestorationShortcut` (Default: `Cmd+Ctrl+V`).
*   **Concurrency Pattern (CRITICAL)**:
    *   **Conflated Task**: Similar to the Masking Loop, the restoration process MUST run in a **detached cancellable Task** to handle rapid triggers safely.
    *   **Non-Blocking**: All processing (Regex -> Session Lookup -> Paste) MUST occur off the Main Actor.
*   **Logic Steps**:
    1.  **Read**: Get current string from `PasteboardService`. Guard for empty.
    2.  **Scan**: Use `RegexEngine` to identify all `{{CM_T:[a-f0-9]{12}}}` placeholders (matching the established token format).
    3.  **Lookup**: Batch resolve tokens against `SessionActor`.
        *   **Hit**: Retrieve original secret.
        *   **Miss**: Replace with explicit error marker `>>MISSING_SECRET<<`.
    4.  **Reconstruct**: Replace placeholders with resolved values or error markers using `RegexEngine.replace`.
    5.  **Action Branching**:
        *   **If Restoration Occurred**:
            *   **Secure Paste Dance**: Execute the sequence to inject `restoredContent` and restore safety.
            *   **Feedback**: HUD "Restored" (Green) + Tink Sound.
        *   **If No Tokens Found**:
            *   **No-Op**: Show HUD "No Tokens Found" (Grey). Do NOT modify clipboard. Do NOT trigger paste. This forces the user to use standard `Cmd+V` for normal content, ensuring safety.

### 2. Technical Specifications (API Contracts)

#### **SessionActor Enhancements**
*   **Method**: `func resolve(tokens: [String]) async -> [String: String?]`
*   **Requirement**: Returns a mapping of the short ID (the part inside `{{CM_T:...}}`) to the original secret. If not found, return `nil` for that key.

#### **RegexEngine Enhancements**
*   **Method**: `func replace(content: String, mapping: [String: String?]) async -> String`
*   **Requirement**: Efficiently replaces all `{{CM_T:id}}` occurrences. If `mapping[id]` is `nil`, replace with `>>MISSING_SECRET<<`. Use a single-pass scan if possible.

#### **KeyboardService Enhancements**
*   **Method**: `func simulatePaste() async`
*   **Requirement (CRITICAL)**: Simulate `Cmd+V`. MUST ensure modifier keys from the trigger (`Cmd+Ctrl+V`) are released or masked appropriately to avoid `Cmd+Ctrl+V` + `V` conflicts. Use a small buffer delay (~50ms) before posting events.

### 3. The "Secure Paste Dance" (Reducer Logic)

This sequence MUST be implemented in the `AppStore` reducer to ensure zero leakage:

1.  **Capture Original**: `let maskedContent = await pasteboard.string()`
2.  **Prepare Secret**: `await pasteboard.setString(restoredContent)`
3.  **Execute Paste**: `await keyboard.simulatePaste()`
4.  **Wait**: `try? await Task.sleep(nanoseconds: 200_000_000)` (200ms for system to consume).
5.  **Restore Safety**: `await pasteboard.setString(maskedContent)`
    *   **Cleanup**: Use `defer { await pasteboard.setString(maskedContent) }` to ensure the sensitive content is cleared even if the Task is cancelled or fails.

### 4. Fail-Safe Protocol

*   **Explicit Error Tokens**: Any token not found in `SessionActor` MUST be replaced with `>>MISSING_SECRET<<`.
*   **Atomic Fidelity**: Partial restoration is allowed, BUT missing secrets must be visibly broken to prevent silent failures.

### 5. Feedback System

*   **Visual**:
    *   Success: HUD "Restored" (Green).
    *   Partial/Missing: HUD "Missing Secrets" (Red) + Haptic Warning.
    *   No Tokens: HUD "No Tokens" (Grey).
*   **Audio/Haptic**:
    *   Success: "Tink" + Tap.
    *   Error: "Thump" + Alignment.

## Tasks

- [x] **Service Enhancements**
    - [x] Update `KeyboardService` with `simulatePaste()` (Cmd+V) and modifier safety logic.
    - [x] Update `SessionActor` with `resolve(tokens: [String]) -> [String: String?]` batch lookup.
    - [x] Update `RegexEngine` with `replace(content: String, mapping: [String: String?])` and `>>MISSING_SECRET<<` handling.
- [x] **Restoration Logic (AppStore)**
    - [x] Implement `.startRestoration` action handling with "Secure Paste Dance".
    - [x] Implement Task cancellation/conflation.
- [x] **Feedback Wiring**
    - [x] Wire up `.restorationSequenceCompleted` to HUD/Audio/Haptics.
- [x] **Tests**
    - [x] `RestorationLoopTests.swift`:
        - [x] Test full hit (all tokens found).
        - [x] Test partial miss (insert `>>MISSING_SECRET<<`).
        - [x] Test "No Tokens" scenario (verify no clipboard change).
        - [x] Test "Secure Paste Dance" cleanup (verify clipboard is restored to safe state).

## Dev Notes

### Architecture Compliance

*   **Secure Paste Dance**: The `defer` block is non-negotiable. We must NEVER leave unmasked secrets on the clipboard longer than the milliseconds required to paste.
*   **KeyboardService**: The `Cmd+Ctrl+V` shortcut is a "greedy" shortcut. The simulation must be robust against physically held keys.

### Previous Story Intelligence

*   **Token Pattern**: Follow `{{CM_T:id}}` as implemented in `RegexEngine.swift` (Story 1.4/1.5).
*   **Conflated Task**: Re-use the exact same cancellation pattern used in `MaskingLoop`.

### References

*   [Source: Core/Services/KeyboardService.swift]
*   [Source: Features/Session/SessionActor.swift]
*   [Source: Features/Clipboard/RegexEngine.swift]
*   [Source: App/AppStore.swift]

## Dev Agent Record

### Implementation Plan
- Implemented `KeyboardService.simulatePaste()` ensuring modifier safety by forcing `.maskCommand` flag on generated events.
- Implemented `SessionActor.resolve(tokens:)` for batch lookup.
- Implemented `RegexEngine.replace(content:mapping:)` with `>>MISSING_SECRET<<` handling.
- Implemented `AppStore` reduction for `.startRestoration` including "Secure Paste Dance" and feedback wiring.

### Completion Notes
- Verified `simulatePaste` implementation with API tests.
- Verified `SessionActor.resolve` with batch lookup tests.
- Verified `RegexEngine.replace` with unit tests covering missing secret scenarios.
- Implemented robust `AppStore` logic with task cancellation safety.
- Verified Restoration Loop logic with comprehensive tests in `RestorationLoopTests.swift`.

## File List
- CodeMask/CodeMask/Core/Services/KeyboardService.swift
- CodeMask/CodeMaskTests/CodeMaskTests.swift
- CodeMask/CodeMask/Features/Session/SessionActor.swift
- CodeMask/CodeMaskTests/Features/Session/SessionActorTests.swift
- CodeMask/CodeMask/Features/Clipboard/RegexEngine.swift
- CodeMask/CodeMaskTests/Features/Clipboard/RegexEngineTests.swift
- CodeMask/CodeMaskTests/Mocks/MockServices.swift
- CodeMask/CodeMask/App/AppStore.swift
- CodeMask/CodeMask/Features/Clipboard/Clipboard.swift
- CodeMask/CodeMask/Features/HUD/HUD.swift
- CodeMask/CodeMask/Features/HUD/HUDView.swift
- CodeMask/CodeMaskTests/Features/Clipboard/RestorationLoopTests.swift

## Change Log
- 2026-02-04: Implemented KeyboardService.simulatePaste.
- 2026-02-04: Implemented SessionActor.resolve.
- 2026-02-04: Implemented RegexEngine.replace.
- 2026-02-04: Implemented AppStore restoration logic.
- 2026-02-04: Implemented RestorationLoopTests.