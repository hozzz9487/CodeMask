# Story 2.3: Guardian Mode: Passive Clipboard Monitor

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the app to passively monitor my clipboard in the background,
so that it knows when I have copied sensitive data and can proactively protect me from accidental exposure.

## Implementation Scope

### Do
- Implement clipboard change detection via `NSPasteboard.changeCount` polling.
- Reuse existing `environment.regexEngine` for sensitivity checks.
- Update security state via existing `updateHasSecrets(_:)` and danger evaluation path.
- Mark sensitive clipboard content with `org.nspasteboard.TransientType`.
- Skip regex scan for payloads larger than 500KB.

### Do Not
- Do not introduce `RegexEngine.shared` singleton usage.
- Do not introduce non-existent session action `.didDetectSecrets(...)`.
- Do not change token format; current format is `{{CM_T:<12-hex>}}`.
- Do not implement Story 2.5 alert UX or Story 2.7 bypass HUD here.

## Acceptance Criteria

1. **Given** Guardian Mode is enabled (default `true`)
   **When** clipboard `changeCount` changes
   **Then** monitor detects the change within 500ms.

2. **Given** a clipboard change is detected
   **When** content is scanned
   **Then** scan reuses injected `environment.regexEngine`
   **And** monitoring + scan path stays under <1% average CPU using polling + conflated task cancellation.

3. **Given** scan finds unmasked sensitive content
   **Then** app sets `hasSecrets = true` through centralized mutation (`updateHasSecrets(true)`)
   **And** if browser is focused, danger state becomes active through existing guardian reducer flow
   **And** clipboard is marked with `org.nspasteboard.TransientType`.

4. **Given** scan finds only masked tokens in current format (`{{CM_T:xxxxxxxxxxxx}}`)
   **Then** content is treated as safe for Guardian detection
   **And** no new danger state is triggered from this scan result alone.

5. **Given** clipboard payload is larger than 500KB
   **When** monitor receives the change
   **Then** regex scanning is skipped to avoid UI/CPU spikes
   **And** monitoring loop continues normally.

6. **Given** monitor writes transient marker metadata
   **When** pasteboard `changeCount` increments due to the app's own write
   **Then** monitor must suppress re-processing of that self-authored change.

## Technical Requirements

### Architecture & Pattern Compliance

- **Module Location**: `CodeMask/CodeMask/Features/Guardian/`
- **Namespace**: extend existing `enum Guardian` from Story 2.4.
- **Monitoring model**: implement `ClipboardMonitor` as an `actor` using polling loop + conflated analysis task.
- **Conflated Task rule**: only newest clipboard version may be analyzed; cancel stale analysis task before starting a new one.
- **State flow**: monitor emits Guardian actions; AppStore reducer updates guardian/session state.
- **Danger evaluation**: continue using existing path in `AppStore+Guardian.evaluateDangerState()`.

### Existing APIs To Reuse

- `environment.regexEngine` injection from `AppEnvironment`.
- `updateHasSecrets(_:)` in `AppStore+Guardian`.
- Existing browser focus actions from Story 2.4.

### Required API Additions

To support this story without direct `NSPasteboard.general` coupling in feature code, extend pasteboard abstraction:

- `PasteboardServiceProtocol`
  - `func changeCount() async -> Int`
  - `func availableTypes() async -> [NSPasteboard.PasteboardType]`
  - `func addTransientTypePreservingString() async -> Int?`

Behavior notes:
- `addTransientTypePreservingString()` must preserve current string payload and add transient type.
- Return latest `changeCount` after write so monitor can suppress self-trigger loops.

### Detection Rules

- Sensitive if regex rule match exists on unmasked content.
- Treat token-only content in active token format (`{{CM_T:...}}`) as safe.
- If content is empty or unavailable, mark safe (`updateHasSecrets(false)`) unless other active evidence keeps it true.

### Performance Rules

- Poll interval target: 250ms to satisfy 500ms detection requirement.
- Analysis runs off main thread (`Task.detached(priority: .utility)` or equivalent actor-bound background work).
- No unbounded queueing; at most one active analysis task.

## Tasks / Subtasks

- [ ] **Task 1: Extend Guardian State and Actions**
- [ ] Add `Guardian.State.isMonitoring: Bool`.
- [ ] Add Guardian actions with event semantics:
- [ ] `.didStartMonitoring`
- [ ] `.didStopMonitoring`
- [ ] `.didDetectClipboardSensitivity(isSensitive: Bool)`
- [ ] `.didSkipClipboardScanForLargePayload`
- [ ] `.didApplyTransientMarker(changeCount: Int?)`
- [ ] Update `AppStore+Guardian.swift` reducer mapping.

- [ ] **Task 2: Implement ClipboardMonitor**
- [ ] Create `CodeMask/CodeMask/Features/Guardian/ClipboardMonitor.swift`.
- [ ] Track `lastObservedChangeCount` and `lastSelfAuthoredChangeCount`.
- [ ] Implement polling loop (`~250ms`) and conflated analysis task cancellation.
- [ ] Skip self-authored change counts.

- [ ] **Task 3: Integrate Regex and Token-Aware Safety Logic**
- [ ] Read pasteboard string through protocol.
- [ ] Apply 500KB guard before regex work.
- [ ] Detect token-only content using current token format (`{{CM_T:<12 hex>}}`) and treat as safe.
- [ ] Dispatch sensitivity result action.

- [ ] **Task 4: Implement Transient Marking Safely**
- [ ] Extend pasteboard service to add transient type while preserving string data.
- [ ] After write, store returned `changeCount` as self-authored to prevent re-scan loop.

- [ ] **Task 5: Lifecycle Integration**
- [ ] Wire monitor dependency into `AppEnvironment`.
- [ ] Start/stop monitoring from app lifecycle.
- [ ] Respect Guardian Mode toggle (default true).

- [ ] **Task 6: Unit Tests**
- [ ] Mock pasteboard protocol for deterministic tests.
- [ ] Verify conflated cancellation under rapid `changeCount` updates.
- [ ] Verify >500KB bypass behavior.
- [ ] Verify self-authored transient write suppression.
- [ ] Verify browser-focused + sensitive content drives warning state through existing path.

## Regression Guardrails

- Do not break Story 2.4 browser detection path.
- Do not overwrite clipboard payload when adding transient type.
- Do not regress menu bar warning logic driven by `session.isDanger`.

## Dev Notes

- `NSPasteboard.changeCount` is global and monotonic; compare against local counters only.
- Reading pasteboard string should remain abstracted behind service protocol for testability.
- Keep monitoring side effects out of UI layer; reducer remains source of truth.

### Project Structure Notes

- **File Location**: `CodeMask/CodeMask/Features/Guardian/`
- **Test Location**: `CodeMask/CodeMaskTests/Features/Guardian/`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3: Guardian Mode: Passive Clipboard Monitor]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns and Consistency Rules]
- [Source: _bmad-output/planning-artifacts/project-context.md#Critical Implementation Rules]
- [Source: CodeMask/CodeMask/Features/Guardian/Guardian.swift]
- [Source: CodeMask/CodeMask/App/Reducers/AppStore+Guardian.swift]
- [Source: CodeMask/CodeMask/Core/Services/PasteboardService.swift]
- [Source: CodeMask/CodeMask/App/AppEnvironment.swift]
- [Source: CodeMask/CodeMask/Features/Clipboard/RegexEngine.swift]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
