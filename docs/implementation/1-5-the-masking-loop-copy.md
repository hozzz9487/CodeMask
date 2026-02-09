# Story 1.5: The Masking Loop (Copy)

Status: done

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


## Review Follow-ups (AI)

- [x] [AI-Review][HIGH] HUD Race Condition: `.show` action starts a new `Task` without cancelling the previous auto-hide task. Multiple triggers will cause HUD to disappear prematurely. [AppStore.swift:217]
- [x] [AI-Review][HIGH] State Deadlock on Cancellation: When `maskingTask` is cancelled via `Task.isCancelled`, it returns early without dispatching `.maskingSequenceCompleted`. This leaves `clipboard.isMasking = true` indefinitely. [AppStore.swift:151]
- [x] [AI-Review][MEDIUM] Missing Resource Preparation: Story AC 3 requires calling `prepare()` on haptics and audio services at launch. Currently missing in `AppStore.init` or `didLaunch`. [AppStore.swift:54]
- [x] [AI-Review][MEDIUM] Task Reference Cleanup: `maskingTask` reference should be nil'd out in `.maskingSequenceCompleted` to avoid holding onto finished tasks. [AppStore.swift:183]
- [x] [AI-Review][LOW] Documentation Consistency: The File List mentions `ProtocolConformanceTests.swift` in `Core/Services`, but it was moved to `CodeMaskTests`. Update story to reflect git reality. [1-5-the-masking-loop-copy.md:122]
- [ ] [AI-Review][MEDIUM] Test Fragility: `MaskingLoopTests.testMaskingLoop_RaceCondition` relies on non-deterministic `Task.sleep`. Refactor to use `AsyncStream` or continuations for precise task state synchronization. [MaskingLoopTests.swift:90]
- [ ] [AI-Review][LOW] Tech Debt: `MockRegexEngine` uses brittle injection of `MatchResult`. Refactor to support dynamic content matching for more robust testing. [MockServices.swift]
- [x] [AI-Review][CRITICAL] State Corruption on Task Cancellation: Removed `defer` block in `AppStore.swift` that was incorrectly dispatching success/failure on cancellation, causing false positive "Secured" feedback during rapid triggers.
- [x] [AI-Review][MEDIUM] Race Condition Test Flaw: Updated `MaskingLoopTests.swift` to strictly verify that cancelled tasks produce ZERO audio/haptic side effects.

## Dev Agent Record


### Agent Model Used

{{agent_model_name_version}}
- Implementation Agent (Gemini)
- Code Review Agent (Gemini)

### Implementation Notes

- **Concurrency**: Implemented "Conflated Task Pattern" in `AppStore.reduce(clipboard:)` using `Task.detached` and `maskingTask?.cancel()`. Verified with `MaskingLoopTests.testMaskingLoop_RaceCondition`.
- **Services**: Created `PasteboardService`, `HapticService`, `AudioService` in `Core/Services`. Added `HUD` feature state.
- **Session Support**: Updated `SessionActor` to support `store(batch:)` with `String` keys to handle `Token` mapping.
- **Testing**: Created `MockServices` and `MaskingLoopTests`. Verified 100% pass.
- **Security**: Used `OSAllocatedUnfairLock` for `AudioService` cache thread safety.

### Debug Log References

### Completion Notes List

- ✅ Resolved review finding [HIGH]: HUD Race Condition - Added `hudAutoHideTask` tracking and cancellation in `reduce(hud:)`. Created comprehensive race condition tests.
- ✅ Resolved review finding [HIGH]: State Deadlock on Cancellation - Added `defer` cleanup in masking task to ensure state reset on cancellation.
- ✅ Resolved review finding [MEDIUM]: Missing Resource Preparation - Added `prepare()` calls for haptics and audio in `.didLaunch`.
- ✅ Resolved review finding [MEDIUM]: Task Reference Cleanup - Added `maskingTask = nil` in `.maskingSequenceCompleted`.
- ✅ Resolved review finding [LOW]: Documentation Consistency - Corrected File List to reflect actual test file location.
- ✅ Resolved review finding [CRITICAL]: State Corruption on Task Cancellation - Removed incorrect `defer` logic; validated with strict tests.
- ✅ Resolved review finding [MEDIUM]: Race Condition Test Flaw - Strengthened `testMaskingLoop_RaceCondition` assertions.

### File List

- CodeMask/CodeMask/Core/Services/PasteboardService.swift
- CodeMask/CodeMask/Core/Services/HapticService.swift
- CodeMask/CodeMask/Core/Services/AudioService.swift

- CodeMask/CodeMask/Features/Clipboard/RegexEngine.swift
- CodeMask/CodeMask/Features/Clipboard/Clipboard.swift
- CodeMask/CodeMask/Features/HUD/HUD.swift
- CodeMask/CodeMask/Features/Session/SessionActor.swift
- CodeMask/CodeMask/App/AppEnvironment.swift
- CodeMask/CodeMask/App/AppStore.swift
- CodeMask/CodeMaskTests/Core/Services/ProtocolConformanceTests.swift
- CodeMask/CodeMaskTests/Mocks/MockServices.swift
- CodeMask/CodeMaskTests/Features/Clipboard/MaskingLoopTests.swift
- CodeMaskTests/Features/HUD/HUDRaceConditionTests.swift

## Change Log

- 2026-01-30: Implemented Masking Loop logic, added services (Pasteboard, Haptic, Audio), updated SessionActor, added Tests. (Gemini)
- 2026-01-30: Addressed code review findings - 5 items resolved: HUD race condition fix, state deadlock fix, resource preparation, task cleanup, documentation update. (Claude 4.5 Sonnet)
- 2026-02-02: Fixed Critical State Corruption on Task Cancellation and strengthened Race Condition tests. (Gemini)
