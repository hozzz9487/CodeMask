# System-Level Test Design

## Testability Assessment

- **Controllability**: **PASS**
  - **Strengths**: The `AppStore` + `SessionActor` architecture provides a single point of entry for state changes, making it highly controllable. Dependency injection via `AppEnvironment` allows swapping `ClipboardService` and `ProfileManager` with mocks.
  - **Concerns**: Testing `mlock` and low-level memory management requires specialized test harnesses. Global hotkeys are difficult to simulate in headless CI environments.

- **Observability**: **PASS**
  - **Strengths**: Unidirectional flow allows observing all state transitions via the Store. The "Local Security Audit Log" (FR24) provides a secondary verification channel.
  - **Concerns**: Verifying the *absence* of data in swap space (S1) is difficult to observe directly from XCTest.

- **Reliability**: **PASS**
  - **Strengths**: Pure Swift actors prevent data races. Protocol-based mocking ensures tests are isolated from the real system clipboard.
  - **Concerns**: The "Conflated Task" pattern for clipboard monitoring must be tested thoroughly to ensure it doesn't drop events or introduce race conditions under load.

## Architecturally Significant Requirements (ASRs)

| ID | Requirement | Category | Risk Score | Test Strategy |
|----|-------------|----------|------------|---------------|
| **P1** | **Latency < 100ms** | PERF | 6 (High) | `XCTMetric` performance tests on `MaskingEngine`. |
| **S1** | **Zero-Persistence (mlock)** | SEC | 9 (Critical) | Integration tests verifying `UnsafeMutableRawPointer` handling; Manual audit of swap usage. |
| **R1** | **100% Deterministic Restoration** | DATA | 9 (Critical) | Property-based testing (Fuzzing) with generated code blocks and random tokens. |
| **S3** | **Profile Isolation** | SEC | 9 (Critical) | Unit tests verifying `SessionActor` state is strictly scoped to `ProfileID`. |
| **U1** | **Native DX (HUD)** | BUS | 4 (Med) | UI Tests for HUD appearance/disappearance timing. |
| **P2** | **Guardian CPU < 1%** | PERF | 4 (Med) | Long-running instrumented tests mocking high-frequency clipboard changes. |

## Test Levels Strategy

- **Unit Tests (70%)**:
  - Focus: `RegexEngine`, `SessionActor` (Logic), `TokenGenerator`, `ProfileManager` (JSON parsing).
  - Rationale: Most complexity lies in the pure logic of masking/restoring and state management. Fast feedback is crucial.

- **Integration Tests (20%)**:
  - Focus: `ClipboardMonitor` -> `AppStore` -> `SessionActor` flow.
  - Strategy: Use `MockClipboardService` to simulate system events and verify `AppStore` state changes. Verify `ProfileSwitching` clears the session.

- **E2E/UI Tests (10%)**:
  - Focus: Critical User Journeys (Alex, Sarah).
  - Strategy: Verify Menu Bar icon states, HUD appearance, and Preferences window interactions.
  - Limitation: Actual global hotkey triggering might need manual verification or specialized UI automation tools if CI is headless.

## NFR Testing Approach

- **Security (S1, S2, S4)**:
  - **Memory Safety**: Unit tests to verify `SessionActor` correctly calls `mlock`/`munlock`.
  - **Lifecycle**: Test "Sleep/Lock" notification handlers to ensure `purge` action is dispatched.
  - **Local-Only**: Static analysis to ensure no network APIs (`URLSession`) are used in Core Logic.

- **Performance (P1, P2)**:
  - **Benchmarking**: Use `XCTest` `measure` blocks for the Regex engine with large payloads (up to 500KB).
  - **Throttling**: Verify `GuardianMode` bypass logic for >500KB payloads using mock data.

- **Reliability (R1, R2, R3)**:
  - **Fuzzing**: Generate random code snippets, mask them, restore them, and assert `original == restored`.
  - **Concurrency**: Stress test `ClipboardMonitor` with rapid mock updates to verify `Conflated Task` behavior.

- **Maintainability**:
  - **Mocking**: strictly enforce `Protocol-Oriented` design to keep tests decoupled from `AppKit`.

## Test Environment Requirements

- **Local Machine**: macOS 14.0+ (Sonoma/Sequoia) with Xcode 15+.
- **CI/CD**: macOS runner with "Accessibility" permissions enabled (if possible) or mocked.
- **Tools**: `XCTest` (Built-in), `Swift Testing` (Macro-based, optional but recommended for parameterized tests).

## Testability Concerns

1.  **Global Hotkey Testing**: `Cmd+Opt+C` interception requires "Input Monitoring" permissions which are hard to grant in CI.
    -   *Mitigation*: Isolate the "Hotkey Handler" logic from the "Action Trigger". Test the Trigger logic via Unit/Integration tests. Manually test the Hotkey registration.
2.  **Memory Locking Verification**: `mlock` success is OS-dependent and hard to verify from user space without root or complex inspection.
    -   *Mitigation*: Trust the system API return codes in tests. Add runtime logging for `mlock` failures.

## Recommendations for Sprint 0

1.  **Scaffold Test Target**: Ensure `CodeMaskTests` is set up with a `MockClipboardService` immediately.
2.  **Performance Baseline**: Write a benchmark test for `Swift Regex` early to confirm the <100ms hypothesis for complex patterns.
3.  **Fuzz Test Setup**: Create a simple "Round Trip" fuzzer for the Mask/Restore logic to catch edge cases early.
