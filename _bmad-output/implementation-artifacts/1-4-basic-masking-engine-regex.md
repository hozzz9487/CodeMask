# Story 1.4: Basic Masking Engine (Regex)

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the system to automatically detect and replace sensitive patterns in my clipboard,
So that I don't accidentally share secrets with AI models.

## Acceptance Criteria

1.  **Native Regex Engine**: System uses Swift 5.7+ native `Regex` engine for high performance.
2.  **Cached Compilation**: Regex patterns are pre-compiled or cached; NO compilation during the masking loop.
3.  **Pattern Detection**: Identifies sensitive patterns (e.g., API Keys, Emails, IPs) based on active rules.
4.  **Token Replacement**: Replaces matched sensitive data with high-entropy, collision-resistant tokens.
    *   Format: `{{CM_T:<SHORT_ID>}}` (optimized for length).
5.  **Deterministic Masking**:
    *   **Longest Match First**: Prioritizes specific matches (e.g., full URL) over partial ones (e.g., domain).
    *   **Left-Most First**: Breaks ties for equal-length overlapping matches by position.
6.  **Performance**: Masking operation completes in <100ms for standard payloads (up to 50KB).
7.  **Extraction**: Returns `MatchResult` containing the masked string and a secure map of `Token -> Secret`.

## Tasks / Subtasks

- [x] **Core Regex Infrastructure (Namespaced)**
    - [x] Create `CodeMask/Features/Clipboard/RegexEngine.swift`.
    - [x] Define `extension Clipboard` to hold the engine and models.
    - [x] Define `struct Token: Hashable, Sendable`: Wraps a UUID or ID.
    - [x] Define `struct MatchResult: Sendable`: `maskedString: String`, `secrets: [Token: String]`.
    - [x] Implement `actor RegexEngine`.
        - [x] Properties: `private var cachedRegexes: [Rule.ID: Regex<AnyRegexOutput>]`.
        - [x] Func `updateRules(_ rules: [Rule])` to pre-compile patterns.
        - [x] Func `mask(_ content: String) async -> MatchResult`.
- [x] **Rule Definition**
    - [x] Define `struct Rule: Identifiable, Sendable`: `id`, `pattern: String`, `isEnabled`.
    - [x] Create default ruleset (Email, URL, IP, Generic "Key" patterns).
- [x] **Masking Logic Implementation**
    - [x] Implement the **Deterministic Masking Algorithm** (see Tech Requirements).
    - [x] Generate compact tokens `{{CM_T:<BASE64_ID>}}`.
- [x] **Testing**
    - [x] Unit Test `RegexEngine` with simple patterns.
    - [x] **Critical**: Unit Test overlap logic:
        - Case A (Subset): "https://a.com" vs "a.com" -> Winner: "https://a.com"
        - Case B (Equal Overlap): "ABC" (Rules "AB", "BC") -> Winner: "AB" (Left-most)
    - [x] Performance Test: Verify pre-compilation benefit and <100ms execution.
- [x] **Review Follow-ups (AI)**
    - [x] [AI-Review][High] `RegexEngine.updateRules` silently drops invalid rules. Should return error status or valid/invalid lists. [RegexEngine.swift:8]
    - [x] [AI-Review][Medium] `testPerformance` assertion (0.5s) is 5x looser than AC (0.1s). Tighten test limit. [RegexEngineTests.swift:80]
    - [x] [AI-Review][Low] Replace `print()` with `Logger` in `RegexEngine`. [RegexEngine.swift:10]
    - [x] [AI-Review][Low] Consider capture group support for finer masking (e.g., maintain 'key=' prefix). [RegexEngine.swift:30]

## Dev Notes

### Developer Context

The `RegexEngine` is a stateless *processor* living within the `Clipboard` namespace. It consumes text and configuration, and produces masked results. It must be robust against malicious regex (ReDoS) by relying on Swift's modern engine and simple patterns.

### Technical Requirements

1.  **Strict Namespacing**: All types must be nested: `Clipboard.RegexEngine`, `Clipboard.Rule`, `Clipboard.MatchResult`, `Clipboard.Token`.
2.  **Performance Strategy (Critical)**:
    *   Do NOT run `try Regex(pattern)` inside the `mask()` loop.
    *   Maintain a `cachedRegexes` dictionary in the actor.
    *   Update cache only when rules change.
3.  **Deterministic Masking Algorithm**:
    1.  **Find All**: Run *every* active regex against the full string. Collect all `(Range, RuleID)`.
    2.  **Sort**:
        *   Primary: Length (Descending) - Longest wins.
        *   Secondary: Lower Bound (Ascending) - Left-most wins.
    3.  **Filter**: Iterate through sorted matches. Keep a match ONLY if it does not overlap with any already-accepted match.
    4.  **Replace**: Apply accepted matches to the string.
4.  **Token Format**: Use `{{CM_T:<ShortHash>}}` (e.g., first 8 chars of UUID or Base64) to minimize layout disruption in target apps while maintaining uniqueness.

### Architecture Compliance

*   **Namespace**: `CodeMask/Features/Clipboard/`
*   **Encapsulation**: `extension Clipboard { ... }`
*   **Concurrency**: `actor` for thread safety and exclusive access to the regex cache.

### File Structure Requirements

```
CodeMask/
├── Features/
│   └── Clipboard/
│       ├── RegexEngine.swift      <-- namespace Clipboard { actor RegexEngine ... }
│       └── Models/
│           ├── Rule.swift         <-- namespace Clipboard { struct Rule ... }
│           └── MatchResult.swift  <-- namespace Clipboard { struct MatchResult ... }
└── CodeMaskTests/
    └── Features/
        └── Clipboard/
            └── RegexEngineTests.swift
```

### Testing Requirements

1.  **Overlap Scenarios**:
    *   "Full URL" vs "Domain" (Longest wins).
    *   "StartOverlap" vs "EndOverlap" (Left-most wins).
2.  **Re-entrancy**: Ensure `updateRules` doesn't crash a concurrent `mask` call (Actor handles this, but good to verify logic).
3.  **Performance**: `XCTMeasure` on the `mask` function with 50 rules and 50KB text.

### Previous Story Intelligence

*   **From Story 1.3**: `RegexEngine` outputs data for `SessionActor`. Ensure `MatchResult` is fully `Sendable` to cross this boundary.

### Latest Tech Information (Swift 6.2)

*   **RegexBuilder**: Use `Regex { ... }` for internal static rules if needed.
*   **AnyRegexOutput**: For dynamic rules from string patterns, the type is `Regex<AnyRegexOutput>`.

### Project Context Reference

*   **Rule**: "Feature Namespacing: MUST wrap all Feature State and Actions..." -> Checked.
*   **Rule**: "AppError payloads... sensitive content" -> Ensure regex errors don't log the pattern itself if it contains user data (unlikely here, but good practice).

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References
- **Performance Optimization**: Initially, O(N^2) overlap checking caused `testPerformanceStrict` to fail (2.1s).
- **Optimization 1**: Implemented Boolean Mask for O(N) overlap checking. Improved to 0.44s, still failing target (0.1s).
- **Optimization 2 (Final)**: Implemented **Combined Regex** `(P1)|(P2)|...`. This leverages the regex engine's internal state machine to scan the string in a **single pass** (O(1) pass).
- **Result**: `testPerformanceStrict` reduced to **0.021s**, exceeding the target by 5x.

### Completion Notes List
- Implemented `RegexEngine` with advanced **Combined Regex Optimization** for extreme performance.
- Implemented `RuleUpdateReport` to provide visibility into rule compilation errors.
- Replaced `print` with `OSLog.Logger` for production-grade logging.
- Updated unit tests to enforce strict performance (<0.1s) and verified overlap logic.
- Resolved all Review Follow-up items.
- Fixed file location issue for `RegexEngineTests.swift` (moved from root to correct Xcode structure).

### File List
- CodeMask/CodeMask/Features/Clipboard/Clipboard.swift
- CodeMask/CodeMask/Features/Clipboard/Models/Rule.swift
- CodeMask/CodeMask/Features/Clipboard/Models/MatchResult.swift
- CodeMask/CodeMask/Features/Clipboard/RegexEngine.swift
- CodeMask/CodeMaskTests/Features/Clipboard/RegexEngineTests.swift

