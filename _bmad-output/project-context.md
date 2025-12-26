---
project_name: 'CodeMask'
user_name: 'Edison'
date: '2025-12-23'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
status: 'complete'
rule_count: 18
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

*   **Language:** Swift 6.2 (Strict Concurrency enabled)
*   **Platform:** macOS 26 Tahoe (Native Target)
*   **UI Framework:** SwiftUI (Views) + AppKit (NSPanel, NSStatusBar, Carbon Events)
*   **Architecture:** Custom Native Unidirectional Flow (Redux-lite)
*   **Testing:** XCTest (Protocol-Oriented Mocking)
*   **Security:** `mlock` via `UnsafeMutableRawPointer` (Zero Disk Residue)

## Critical Implementation Rules

### Language & Concurrency Rules

*   **Feature Namespacing:** MUST wrap all Feature State and Actions in a namespace enum (e.g., `enum Clipboard { struct State... enum Action... }`).
*   **Event-Based Actions:** Actions MUST describe **Events** (Past Tense, e.g., `.didTapCopy`), NEVER Commands. Views are "dumb" reporters.
*   **Actor State Integrity:** In `actor SessionActor`, use the **Check-After-Await** pattern. After any `await` suspension point, re-verify state (e.g., `guard currentID == id`) to prevent processing stale data due to reentrancy.
*   **Conflated Task Pattern:** For `ClipboardMonitor`, use a "Cancel-then-Start" pattern for polling tasks. Ensure only the *latest* `changeCount` is processed and previous analysis tasks are canceled.
*   **Memory Safety (UAF Prevention):** NEVER pass raw pointers across `await` boundaries. Wrap `UnsafeMutableRawPointer` in a `final class SecureBuffer` (handling `mlock`/`munlock` in `init`/`deinit`) to ensure ARC manages the memory lifecycle correctly during async operations.

### Framework & UI Rules

*   **VRAM Protection:** When hiding the HUD (`NSPanel`), the SwiftUI content MUST be cleared or reset to a neutral state (e.g., `EmptyView`) *before* hiding to prevent sensitive data residue in the Window Server's VRAM buffer.
*   **HUD Synchronization:** The HUD must observe `AppState.hud.isVisible`. Do NOT use internal SwiftUI `@State` for window visibility; rely 100% on the central Store.

### Testing Rules

*   **Conditional mlock Testing:** Tests must check environment capabilities first. Use the `REQUIRE_MLOCK=1` environment variable for local/secure runners to enforce real locking. Standard CI should skip `mlock` validation if privileges are missing.
*   **Validation Tools:** Use platform-specific tools (e.g., `vmmap`) in local developer tests to verify pages are actually wired (locked).
*   **Mock Boundaries:** Inject all system services (Pasteboard, Accessibility) via protocols to enable 100% offline, side-effect-free testing.

### Code Quality & Security Rules

*   **No-Log Leak Prevention:** `AppError` payloads and logs MUST NEVER contain raw sensitive content (e.g., use "Failed to mask item" instead of "Failed to mask 'password123'").
*   **Log Scanner:** Maintain a pre-commit hook that scans for PII or secret patterns in the codebase and logs to prevent accidental leaks.
*   **Error Propagation:** Background actors MUST catch errors and dispatch a `.didEncounterError(AppError)` action. Do NOT "throw" errors across actor/thread boundaries to the UI.

### Development Workflow Rules

*   **Feature-First Branching:** Branches MUST match the `Features/` directory structure using kebab-case and the `type/feature-name` pattern (e.g., `feat/clipboard-monitor`).
*   **Conventional Commits:** Use scoped commits that reflect the feature namespace: `feat(clipboard): add regex engine`.

### Critical Anti-Patterns (The "Don't-Miss" List)

*   **The MainActor Trap:** Updating `NSHostingController.rootView` from a background task causes crashes. Always hop to `@MainActor` *before* updating AppKit/SwiftUI bridging code.
*   **The Over-Isolation Trap:** Avoid marking the entire `AppStore` as `@MainActor`. Keep heavy Regex processing in `nonisolated` functions or background `WorkerActor`s to prevent UI jank.
*   **The Reentrancy Trap:** Assuming actor state is unchanged after an `await`. Always re-validate assumptions after suspension.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge

**For Humans:**

- Keep this file lean and focused on agent needs
- Update when technology stack changes
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2025-12-23
