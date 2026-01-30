# Story 1.5: The Masking Loop (Copy)

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the "Masking Copy" action to be seamless and fast,
So that my development flow is not interrupted while my secrets are secured.

## Acceptance Criteria

1.  **Event Trigger**: The loop is initiated by the Global Hotkey `Cmd+Opt+C` (implemented in Story 1.2).
2.  **Latency Requirement**: The entire loop (Read -> Mask -> Store -> Write) completes in **< 100ms**.
3.  **Data Flow**:
    *   **Read**: Captures current text from System Pasteboard.
    *   **Mask**: Processes text via `Clipboard.RegexEngine` (Story 1.4).
    *   **Store**: Saves the *original* secret map to `Session.SessionActor` (Story 1.3).
    *   **Write**: Writes the *masked* text back to System Pasteboard.
4.  **Feedback**:
    *   **Visual**: Triggers a HUD update (via State change) to show "Secured" (Blue).
    *   **Audio**: Plays a subtle system sound ("Tink").
    *   **Haptic**: Triggers a `generic` haptic tap on the trackpad.
5.  **Error Handling**: If masking fails or clipboard is empty, user is notified via HUD (Red) and no change is made.
6.  **Concurrency**: Operations must not block the Main Thread (UI), except for the minimal Pasteboard I/O if required.

## Tasks / Subtasks

- [ ] **Action Definition**
    - [ ] Define `Clipboard.Action.didTriggerMaskingShortcut`: The entry point event.
    - [ ] Define `Clipboard.Action.maskingSequenceCompleted(Result<Clipboard.MatchResult, AppError>)`: The completion event.
- [ ] **Environment Integration**
    - [ ] Extend `AppEnvironment` with `pasteboard: PasteboardServiceProtocol`.
    - [ ] Extend `AppEnvironment` with `haptics: HapticServiceProtocol`.
    - [ ] Extend `AppEnvironment` with `audio: AudioServiceProtocol`.
    - [ ] Implement `LivePasteboardService`: Wraps `NSPasteboard.general`.
    - [ ] Implement `LiveHapticService`: Wraps `NSHapticFeedbackManager`.
    - [ ] Implement `LiveAudioService`: Wraps `NSSound`.
- [ ] **The Masking Loop Logic (Reducer/Effect)**
    - [ ] Implement the side-effect handler for `.didTriggerMaskingShortcut` in `AppReducer` (or Feature Reducer).
    - [ ] **Step 1**: `await environment.pasteboard.string()`. Guard for empty.
    - [ ] **Step 2**: `await environment.regexEngine.mask(content)`.
    - [ ] **Step 3**: `await environment.sessionActor.store(matchResult.secrets)`.
    - [ ] **Step 4**: `await environment.pasteboard.setString(matchResult.maskedString)`.
    - [ ] **Step 5**: Dispatch `.maskingSequenceCompleted(.success)`.
- [ ] **Feedback Integration**
    - [ ] Handle `.maskingSequenceCompleted(.success)`:
        - [ ] Trigger `environment.haptics.play(.generic)`.
        - [ ] Trigger `environment.audio.playSystemSound(.tink)`.
        - [ ] Update `AppState.hud` to show "Secured" (Blue).
    - [ ] Handle `.maskingSequenceCompleted(.failure)`:
        - [ ] Trigger `environment.haptics.play(.alignment)`.
        - [ ] Update `AppState.hud` to show Error.
- [ ] **Testing**
    - [ ] Unit Test: Mock Pasteboard/Session/Regex and verify the flow dispatching correct actions.
    - [ ] Performance Test: Measure the `Effect` execution time (aim for < 50ms logic time).

## Dev Notes

### Developer Context

This story connects the disparate components built in 1.2, 1.3, and 1.4 into the first usable feature. The critical challenge is **latency**. The user must feel like the copy happened instantly.

### Technical Requirements

1.  **Async/Await Flow**: The side-effect should be a `run { send in ... }` block in the Reducer.
2.  **Pasteboard Threading**: `NSPasteboard` is generally thread-safe but often best accessed from MainActor. If `LivePasteboardService` uses MainActor, ensure the switching cost is minimized.
3.  **Error Handling**: If `RegexEngine` returns no matches (nothing masked), should we still "Store" and "Write"?
    *   *Decision*: If `matchResult.secrets` is empty, do **not** write back to pasteboard (avoid unnecessary churn). Just trigger the "Secured" (or "Clean") feedback to let the user know the system checked it.
    *   *Refinement*: If nothing to mask, maybe show "Safe" (Grey) instead of "Secured" (Blue)? *Decision*: Stick to simple "Secured" for now, or "No Secrets Found" if we want to be verbose. Let's stick to **"Secured"** (Blue) implies "Checked and Safe".
4.  **Audio/Haptics**: Must be non-blocking. Fire and forget.

### Architecture Compliance

*   **Pattern**: Unidirectional Flow. View/Hotkey -> Action -> Reducer -> Effect -> Action -> State.
*   **Protocols**: `PasteboardServiceProtocol`, `HapticServiceProtocol`, `AudioServiceProtocol` are REQUIRED for testing. Do not use `NSPasteboard.general` directly in the Reducer.
*   **Namespacing**: Ensure all new Services are properly organized (e.g., `Core/Services/`).

### Library/Framework Requirements

*   `AppKit` (`NSPasteboard`, `NSHapticFeedbackManager`, `NSSound`).
*   `Swift Concurrency`.

### Testing Requirements

*   **Mocking**: You MUST mock the `PasteboardService` to test the loop without clobbering the real system clipboard during tests.
*   **State Assertion**: Verify that `AppState.hud` transitions correctly after the sequence.

### Previous Story Intelligence

*   **From 1.4**: `RegexEngine` is fast (< 21ms). We have plenty of budget for the rest of the loop.
*   **From 1.3**: `SessionActor` uses `mlock`. Ensure the `store` call is awaited properly.

### Project Context Reference

*   **Rule**: "Actions MUST describe Events". `.didTriggerMaskingShortcut` is perfect.
*   **Rule**: "Inject all system services... via protocols".

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
