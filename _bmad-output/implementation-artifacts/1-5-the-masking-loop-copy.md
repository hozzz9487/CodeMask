# Story 1.5: The Masking Loop (Copy)

Status: review

<!-- Note: Validation COMPLETED. Critical Concurrency & Security Improvements Applied. -->

## Story

As a user,
I want the "Masking Copy" action to be seamless and fast (<100ms),
So that my development flow is not interrupted while my secrets are secured in RAM.

## Acceptance Criteria & Implementation Directives

### 1. The Core Loop (Logic & Concurrency)

*   **Trigger**: Initiated by `.didTriggerMaskingShortcut` (from Story 1.2).
*   **Concurrency Pattern (CRITICAL)**:
    *   **Conflated Task**: To prevent race conditions during rapid triggers, the Reducer MUST use a cancellable task pattern (e.g., `.cancelInFlight` or storing a `Task` UUID). Only the *latest* trigger completes.
    *   **Non-Blocking**: The entire logic chain (Read -> Mask -> Store -> Write) MUST run in a **detached Task** or background actor to avoid blocking the Main Thread/Reducer.
*   **Logic Steps**:
    1.  **Read**: `environment.pasteboard.string()`. Guard for empty.
    2.  **Mask**: `await environment.regexEngine.mask(content)`.
    3.  **Result Branching**:
        *   **If Secrets Found**:
            *   **Store**: `await environment.sessionActor.store(matchResult.secrets)`.
            *   **Write**: `await environment.pasteboard.setString(matchResult.maskedString)`.
            *   **Dispatch**: `.maskingSequenceCompleted(.success(masked: true))`.
        *   **If No Secrets**:
            *   **No-Op Write**: Do NOT write back to pasteboard (avoids churn).
            *   **Dispatch**: `.maskingSequenceCompleted(.success(masked: false))`.
    4.  **Security Hygiene**: Ensure the local `content` variable holding the original string is allowed to deallocate immediately after masking.

### 2. Environment & Protocols

*   **PasteboardServiceProtocol**:
    *   `func string() async -> String?` (Must be MainActor-safe but non-blocking).
    *   `func setString(_ content: String) async` (Must be MainActor-safe).
*   **HapticServiceProtocol**:
    *   `func prepare()` (Warmup engine).
    *   `func play(_ feedback: HapticFeedbackType)` (Fire-and-forget).
*   **AudioServiceProtocol**:
    *   `func prepare(sound: SystemSound)` (Preload).
    *   `func playSystemSound(_ sound: SystemSound)` (Fire-and-forget).

### 3. Feedback System

*   **Visual**:
    *   `.success(masked: true)` -> HUD "Secured" (Blue).
    *   `.success(masked: false)` -> HUD "No Secrets" (Grey/Green) or "Secured" (Blue) - *Decision: Use "Secured" (Blue) for both to indicate safety.*
    *   `.failure` -> HUD "Error" (Red).
*   **Audio/Haptic**:
    *   Success: "Tink" sound + Generic Tap.
    *   Failure: Warning Sound + Alignment Haptic.
    *   **Optimization**: Call `environment.haptics.prepare()` and `environment.audio.prepare(.tink)` on app launch or `.onAppear`.

### 4. Testing Requirements

*   **Race Condition Test**: Simulate Trigger A, wait 10ms, Trigger B. Verify Trigger A is cancelled/ignored and only Trigger B writes to Pasteboard.
*   **Zero-Residue verification**: (Manual/Review) Verify no `print()` logs of the content.
*   **Mocking**: Inject Mocks for all services to verify the flow without touching the real NSPasteboard.

## Tasks

- [x] **Protocol Definition**
    - [x] Define `PasteboardServiceProtocol`, `HapticServiceProtocol`, `AudioServiceProtocol`.
    - [x] Implement `Live` variants wrapping `NSPasteboard`, `NSHapticFeedbackManager`, `NSSound`.
- [x] **Reducer Logic (The Brain)**
    - [x] Handle `.didTriggerMaskingShortcut`:
        - [x] Cancel previous masking task.
        - [x] Start new detached task.
        - [x] Execute Logic Steps (Read -> Mask -> Store -> Write).
        - [x] Dispatch result.
- [x] **Feedback Handling**
    - [x] Handle `.maskingSequenceCompleted`: Trigger HUD/Audio/Haptics.
- [x] **Tests**
    - [x] `MaskingLoopTests.swift`: Cover Success, No-Match, Failure, and Race Conditions.

## Dev Notes

### Technical Requirements

*   **Latency**: The user must feel "Instant". Use `Date` logging in debug to ensure `<100ms`.
*   **State Management**: `AppState.hud` drives the UI. Do not manually present windows from the reducer.
*   **Memory**: While `SecureBuffer` (Story 1.3) protects storage, this loop handles the `String` briefly. This is acceptable for the "Active" operation, provided it's not held in a long-lived property.

### Previous Story Intelligence

*   **From 1.4**: `RegexEngine` returns `MatchResult` which contains the `secrets` map needed for `SessionActor.store`.
*   **From 1.3**: `SessionActor.store` returns a `UUID` (Token), but for this loop, we just need to confirm storage success.

### Project Context Reference

*   **Rule**: "Conflated Task Pattern... for monitoring/high-frequency tasks."
*   **Rule**: "Actions MUST describe Events".


## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}
- Implementation Agent (Gemini)

### Implementation Notes

- **Concurrency**: Implemented "Conflated Task Pattern" in `AppStore.reduce(clipboard:)` using `Task.detached` and `maskingTask?.cancel()`. Verified with `MaskingLoopTests.testMaskingLoop_RaceCondition`.
- **Services**: Created `PasteboardService`, `HapticService`, `AudioService` in `Core/Services`. Added `HUD` feature state.
- **Session Support**: Updated `SessionActor` to support `store(batch:)` with `String` keys to handle `Token` mapping.
- **Testing**: Created `MockServices` and `MaskingLoopTests`. Verified 100% pass.
- **Security**: Used `OSAllocatedUnfairLock` for `AudioService` cache thread safety.

### Debug Log References

### Completion Notes List

### File List

- CodeMask/CodeMask/Core/Services/PasteboardService.swift
- CodeMask/CodeMask/Core/Services/HapticService.swift
- CodeMask/CodeMask/Core/Services/AudioService.swift
- CodeMask/CodeMask/Core/Services/ProtocolConformanceTests.swift (Moved to Tests)
- CodeMask/CodeMask/Features/Clipboard/RegexEngine.swift
- CodeMask/CodeMask/Features/Clipboard/Clipboard.swift
- CodeMask/CodeMask/Features/HUD/HUD.swift
- CodeMask/CodeMask/Features/Session/SessionActor.swift
- CodeMask/CodeMask/App/AppEnvironment.swift
- CodeMask/CodeMask/App/AppStore.swift
- CodeMaskTests/Core/Services/ProtocolConformanceTests.swift
- CodeMaskTests/Mocks/MockServices.swift
- CodeMaskTests/Features/Clipboard/MaskingLoopTests.swift

## Change Log

- 2026-01-30: Implemented Masking Loop logic, added services (Pasteboard, Haptic, Audio), updated SessionActor, added Tests. (Gemini)
