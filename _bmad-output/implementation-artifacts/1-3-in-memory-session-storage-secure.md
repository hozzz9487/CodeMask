# Story 1.3: In-Memory Session Storage (Secure)

Status: ready-for-dev

<!-- Note: Validation COMPLETED. Improvements applied for Critical Security Safety. -->

## Story

As a security-conscious developer,
I want my sensitive data to be stored strictly in RAM and protected from disk swap,
So that no trace of my secrets is ever written to persistent storage.

## Acceptance Criteria

1. **Secure Storage (RAM Only)**: The system stores sensitive strings strictly in volatile memory.
2. **Swap Protection (mlock)**: The memory region holding the secret is locked (`mlock`) to prevent paging to disk.
3. **Exclusive Page Ownership**: Each secret occupies its own physical memory page(s) to prevent `munlock` from exposing neighboring secrets.
4. **Tokenization**: Each secret is associated with a unique, high-entropy token (UUID-based).
5. **Isolation**: Data is logically isolated within the current session.
6. **Retrieval**: System can retrieve the original secret using the correct token.
7. **Secure Cleanup**: Memory is explicitly securely wiped (`memset_s`) and unlocked (`munlock`) upon deallocation.

## Senior Developer Review (AI)

**Status**: ✅ **APPROVED (With Critical Fixes)**
**Review Date**: 2026-01-12
**Reviewer**: Security Auditor Agent

### Action Items
- [x] Fix Shared Page Unlock Hazard (Issue 1) - 🔴 CRITICAL
- [x] Fix Dead Store Elimination Risk (Issue 2) - 🔴 CRITICAL
- [x] Enforce Strict Concurrency Isolation (Issue 3) - 🟡 HIGH

## Tasks / Subtasks

- [ ] **Core Security Infrastructure**
    - [ ] Create `CodeMask/Core/Security/SecureBuffer.swift`
        - [ ] **Critical**: Use `posix_memalign` to allocate memory aligned to `vm_page_size`.
        - [ ] **Critical**: Round up allocation size to nearest `vm_page_size` multiple.
        - [ ] Implement `init(string: String)`: Copy bytes -> `mlock` the full page range.
        - [ ] Implement `deinit`:
            - [ ] Use `memset_s` (or secure equivalent) to zero memory (Prevent Dead Store Elimination).
            - [ ] Call `munlock` on the full page range.
            - [ ] `free` the pointer.
        - [ ] Mark class as `final` and **non-Sendable** (do not conform to `Sendable`).
- [ ] **Session Feature Scaffolding**
    - [ ] Create `CodeMask/Features/Session/Session.swift` (Namespace)
        - [ ] Define `State` (holding `sessionID`).
        - [ ] Define `Action` cases: `.didSecureData(token: UUID)`, `.didRetrieveData(content: String?)`, `.didFail(AppError)`.
- [ ] **Session Actor Implementation**
    - [ ] Create `CodeMask/Features/Session/SessionActor.swift`
        - [ ] Implement `actor SessionActor` conforming to `SessionStorageProtocol`.
        - [ ] Internal storage: `private var storage: [UUID: SecureBuffer]`.
        - [ ] Func `store(content: String) -> UUID`.
        - [ ] Func `retrieve(id: UUID) -> String?`.
        - [ ] Implement "Check-After-Await" pattern for any async reentrancy.
- [ ] **Helper Components**
    - [ ] Create `CodeMask/Features/Session/TokenGenerator.swift` (Simple UUID wrapper).
- [ ] **Integration**
    - [ ] Add `SessionStorageProtocol` to `AppEnvironment`.
    - [ ] Integrate with `AppStore` (Reducer updates).
- [ ] **Testing**
    - [ ] Unit Test `SecureBuffer` (verify lifecycle).
    - [ ] Unit Test `SessionActor` (store/retrieve logic).
    - [ ] **Critical**: Add `REQUIRE_MLOCK=1` check in tests.

## Dev Notes

### Developer Context

This is the **heart** of the security architecture. You are building the vault.
Do NOT use standard `String` for long-term storage.
The flow is: `String` (Transient) -> `SecureBuffer` (Locked RAM) -> `Token` (Public Reference).

### Technical Requirements

1.  **Memory Locking (`mlock`) Strategy (CRITICAL)**:
    *   **Problem**: `mlock` and `munlock` operate on *whole pages*. Standard `malloc` packs small objects onto the same page. If you `munlock` one object, you accidentally unlock its neighbors!
    *   **Solution**: You MUST use `posix_memalign` with alignment `vm_page_size` (usually 16KB on Apple Silicon, 4KB on Intel).
    *   **Allocation**: `size = (payloadSize + vm_page_size - 1) & ~(vm_page_size - 1)` (Round up).
    *   **Lifecycle**:
        1.  `posix_memalign(&ptr, vm_page_size, size)`
        2.  `memcpy(ptr, data, dataLen)`
        3.  `mlock(ptr, size)`
2.  **Secure Cleanup Strategy**:
    *   **Problem**: The compiler sees `memset(ptr, 0, size)` followed immediately by `free(ptr)` and deletes the `memset` call ("Dead Store Elimination").
    *   **Solution**: Use `memset_s` (if available via C-interop) OR cast to `volatile` pointer before zeroing, to force the write.
    *   **Lifecycle**:
        1.  `memset_s(ptr, size, 0, size)`
        2.  `munlock(ptr, size)`
        3.  `free(ptr)`
3.  **Concurrency**:
    *   `SessionActor` must be an `actor`.
    *   `SecureBuffer` must **NOT** escape the actor. It handles the raw pointers.
    *   Return only `UUID` (tokens) or transient `String` (restoration) to callers.

### Architecture Compliance

*   **Namespace**: `CodeMask/Features/Session/`
*   **Pattern**: Actor-isolated state.
*   **Dependencies**: `CodeMask/Core/Security/` for the low-level buffer.
*   **Project Context Rule**: "Memory Safety (UAF Prevention): Wrap `UnsafeMutableRawPointer` in a `final class SecureBuffer`".

### Library & Framework Requirements

*   **Libc**: `import Darwin` (for `mlock`, `munlock`, `memset`).
*   **Swift Standard Library**: `UnsafeMutableRawPointer`, `UnsafeMutableBufferPointer`.
*   **No 3rd Party Crypto**: Use native OS capabilities.

### File Structure Requirements

```
CodeMask/
├── Core/
│   └── Security/
│       └── SecureBuffer.swift     <-- NEW: The low-level security wrapper
├── Features/
│   └── Session/
│       ├── Session.swift          <-- NEW: Namespace (State/Action)
│       ├── SessionActor.swift     <-- NEW: The Actor
│       └── TokenGenerator.swift   <-- NEW: Helper
└── CodeMaskTests/
    └── Features/
        └── Session/
            └── SessionTests.swift <-- NEW: Tests
```

### Testing Requirements

1.  **Unit Tests**:
    *   Test `store` returns a valid UUID.
    *   Test `retrieve` with valid UUID returns original string.
    *   Test `retrieve` with invalid UUID returns `nil`.
2.  **Environment Check**:
    *   In `SecureBuffer` tests, check `getenv("REQUIRE_MLOCK")`. If set and `mlock` fails, fail test. If not set (CI), warn but pass (simulated).

### Previous Story Intelligence

*   **From Story 1.2 (Hotkeys)**:
    *   Use `Unmanaged` or `Unsafe` types carefully.
    *   Explicit cleanup (`deinit`) is vital.
    *   Namespace everything in `Features/Session`.

### Latest Tech Information (Swift 6.2 / macOS 26)

*   **Strict Concurrency**: `SecureBuffer` (a class) should be `Sendable` if passed across boundaries, but ideally it stays *inside* the `SessionActor`. If it's `final` and holds `UnsafeSendable` types, verify Sendability or keep it private to the actor.
*   **Project Rules**: "Wrap UnsafeMutableRawPointer in a final class SecureBuffer".

### Project Context Reference

*   **Rule**: "Actor State Integrity: In `actor SessionActor`, use the **Check-After-Await** pattern."
*   **Rule**: "Memory Safety: ...ensure ARC manages the memory lifecycle correctly..."

## Dev Agent Record

### Agent Model Used
{{agent_model_name_version}}

### Debug Log References
- Check `vmmap` output if running locally to verify wiring.

### Completion Notes List
- Confirmed `mlock` implementation logic.
- Verified Namespace structure matches Project Context.

### File List
- `CodeMask/Core/Security/SecureBuffer.swift`
- `CodeMask/Features/Session/Session.swift`
- `CodeMask/Features/Session/SessionActor.swift`
- `CodeMask/Features/Session/TokenGenerator.swift`
- `CodeMaskTests/Features/Session/SessionTests.swift`
