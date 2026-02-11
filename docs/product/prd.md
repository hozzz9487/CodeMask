---
stepsCompleted: [1, 2, 3, 4, 6, 7, 8, 9, 10]
inputDocuments:
  - /Users/Edison/Desktop/AppProjects/iOS/CodeMask/_bmad-output/analysis/product-brief-CodeMask-2025-12-17.md
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
workflowType: 'prd'
lastStep: 0
project_name: 'CodeMask'
user_name: 'Edison'
date: '2025-12-18'
---

# Product Requirements Document - CodeMask

**Author:** Edison
**Date:** 2025-12-18

## Executive Summary

CodeMask is a **native macOS utility** engineered to resolve the conflict between high-velocity AI adoption and strict IP protection. Unlike browser-based plugins or heavy Python wrappers, CodeMask operates at the **system clipboard level**, providing a frictionless "masking and re-hydration" layer that works across any IDE, communication tool, or terminal. It allows iOS and Android teams to leverage SOTA cloud models (GPT-5, Claude) while guaranteeing that sensitive credentials (API Keys, Bundle IDs, Signing Certs) never leave the local machine in their raw form.

### What Makes This Special

*   **System-Wide, Zero-Latency (<100ms):** Built entirely in Swift with the native macOS Regex engine, CodeMask intercepts clipboard actions with imperceptible delay, preserving the developer's "flow state" while protecting data from any source application.
*   **Bidirectional Deterministic Restoration:** Beyond simple masking, CodeMask maintains a local, ephemeral session map. It automatically "re-hydrates" AI-generated code by restoring the exact original project context (IP) into generic placeholders, eliminating manual "find and replace" drudgery.
*   **Smart Session & Context Isolation:** Designed for the multi-project developer ("The Juggler"). CodeMask supports **distinct Project Profiles**, each with its own isolated Session Map, preventing cross-project data leakage. Memory is intelligently managed—automatically purged upon system sleep, lock, or manual flush—to ensure sensitive data never persists longer than the active workflow requires.
*   **Mobile Ecosystem Intelligence:** Pre-configured with deep knowledge of mobile-specific secrets (Provisioning Profiles, Keystore paths, Gradle signatures) that generic regex tools miss, ensuring protection for specialized iOS/Android workflows out of the box.

## Project Classification

**Technical Type:** desktop_app
**Domain:** developer_tool
**Complexity:** medium
**Project Context:** Greenfield - new project

### Classification Signals

*   **Desktop App:** "native macOS utility", "Cmd+Opt+C", "Menu Bar icon", "System-wide integration"
*   **Developer Tool:** "IDE", "Bundle IDs", "API Keys", "Refactoring", "Mobile Development"
*   **Complexity Factors:**
    *   System-level clipboard monitoring and interception
    *   In-memory session management with complex lifecycle rules
    *   Regex-based pattern matching and deterministic token restoration

## Success Criteria

### User Success

*   **Frictionless Security Protection**: Developers experience <100ms latency when using Cmd+Opt+C/V, ensuring no disruption to their flow state.
*   **Restoration Accuracy (100% Deterministic)**: In multi-turn AI dialogues, the accuracy of restoring to original project variables is 100%. Any restoration failure is considered a critical bug.
*   **Zero Cross-Project Incidents**: After switching profiles, no instances of restoring Project A's sensitive information into Project B's context have occurred.

### Business Success

*   **High Engagement Metrics**: Cmd+Opt+C usage frequency accounts for over 50% of total clipboard operations within the target user group (when the IDE is active).
*   **Word-of-Mouth Adoption**: Recognized as the "must-have security tool for mobile AI development" within communities like Twitter/X and Reddit (r/iOSProgramming).

### Technical Success

*   **Zero Disk Residue**: Verified via automated testing that all Session Map data exists only in memory; data automatically vanishes upon system reboot or lock.
*   **Extreme Performance**: P95 processing latency remains < 100ms, maintaining stability even under high loads (e.g., copying 10,000 lines of code).
*   **Isolation Verification**: Ensure Session Maps between profiles are completely isolated with zero risk of cross-contamination.

## Product Scope

### MVP - Minimum Viable Product

*   **Bidirectional Shortcut Engine**: System-wide Cmd+Opt+C (Mask) and Cmd+Opt+V (Restore).
*   **Project Profile Management**: Support for manual switching between different projects, with **independent filtering rules (Regex Rules) per profile**.
*   **Smart Session Management**: In-memory storage supporting multi-turn dialogues, with automatic purge mechanisms for system lock/sleep.
*   **Mobile Development Presets**: Built-in filtering templates for iOS (Bundle ID, Team ID) and Android (Keystore, Signing configs).

### Growth Features (Post-MVP)

*   **Automatic Profile Awareness**: Automatically switch to the corresponding project profile based on the active window or file path.
*   **Visual Rule Editor**: Enable non-regex experts to easily customize filtering rules via a UI.
*   **Browser Guard**: Issue a warning when unmasked sensitive information is detected being pasted into a web browser.

### Vision (Future)

*   **Team Rule Synchronization**: Support encrypted cloud sync for tech leads to distribute uniform filtering rules to the entire team.
*   **AI Intelligent Detection**: Utilize local small-scale LLMs to identify non-pattern-based sensitive information (e.g., passwords in comments).

## User Journeys

**Journey 1: Alex (The Sprinter) - Preserving the Flow State**
Alex is deep into a complex SwiftUI refactor in Xcode. He hits a roadblock and wants to consult Claude for a more efficient architecture. He selects 300 lines of code containing internal API domains and development keys.
*   **The Action**: Instead of manually scrubbing the code, he hits `Cmd+Opt+C`. The Menu Bar icon flashes "Secured."
*   **The Climax**: He pastes the masked code into AI, receives an optimized solution, and copies it. Back in Xcode, he hits `Cmd+Opt+V`. CodeMask **automatically restores his specific API keys** into the new code structure.
*   **The Resolution**: Alex continues coding without ever leaving his keyboard or breaking his mental model. The "magic restore" saved him 5 minutes of tedious find-and-replace.

**Journey 2: Sarah (The Juggler) - Bulletproof Multi-Project Isolation**
Sarah is a freelancer balancing a Fintech app for Client A and an E-commerce app for Client B. While debugging Client B's login issue, she receives an urgent Slack message about a crash in Client A's production build.
*   **The Action**: She quickly switches to Client A's workspace. Before copying any logs, she uses the global shortcut `Cmd+Ctrl+P` to switch the CodeMask profile to "Client A."
*   **The Climax**: When she copies the crash log, CodeMask isolates the session map to Client A's profile. Even if she accidentally tries to restore code into Client B later, CodeMask's profile isolation prevents cross-project data leakage.
*   **The Resolution**: Sarah manages high-stakes context switches with confidence, knowing her clients' secrets are cryptographically separated in memory.

**Journey 3: Marcus (The Guardian) - Erasing Security Anxiety**
Marcus works in a highly regulated banking environment. He is terrified of a "single slip-up" that could expose customer data or internal endpoints to a public LLM.
*   **The Action**: He installs CodeMask and enables the "High Sensitivity" preset.
*   **The Climax**: As he prepares to paste into a browser, he checks the CodeMask Menu Bar icon. Its steady state gives him a visual "green light" that his clipboard has been sanitized. He occasionally checks the "Recent Masks" log (local only) to verify that SSNs and internal hostnames were caught.
*   **The Resolution**: Marcus can finally leverage SOTA AI tools without the constant low-level stress of accidental data exposure, knowing a native safety net is always active.

**Journey 4: Leo (The Rule Maker) - Standardizing Team Security**
Leo is the Tech Lead for a mobile team. He needs to ensure that all 10 developers on his team are consistently masking the company's proprietary internal library headers.
*   **The Action**: Leo spends 10 minutes crafting a robust Regex set in his CodeMask "Master Profile." 
*   **The Climax**: He exports the configuration as a `ruleset.json` and shares it via the team's internal documentation. Every developer imports it into their CodeMask instance.
*   **The Resolution**: Leo has peace of mind knowing that the entire team is now automatically stripping sensitive internal markers without requiring manual oversight or constant security reviews.

### Journey Requirements Summary

These journeys reveal several critical capability requirements:
*   **Alex's Journey**: High-speed intercept (<100ms), In-memory Session Mapping, and Deterministic Token Restoration.
*   **Sarah's Journey**: Named Project Profiles, Profile Isolation, and Global Profile Switching shortcuts.
*   **Marcus's Journey**: Visual Status Feedback (Menu Bar), Local-only Telemetry/Logs, and High-Sensitivity Regex Presets.
*   **Leo's Journey**: Profile Import/Export (JSON-based), Custom Regex Rule Support, and Rule Sharing.

## Innovation & Novel Patterns

### Detected Innovation Areas

*   **Bidirectional In-Memory Tokenization**: A pioneering approach that maps sensitive data to deterministic placeholders and restores them only upon a specialized "Restore" command, keeping the cloud-based LLM completely blind to private data while the local IDE remains context-complete.
*   **System-Wide Clipboard Interception**: Unlike IDE plugins, CodeMask’s system-level integration allows it to protect data across Slack, browsers, and terminal, creating a unified security perimeter for the developer.
*   **Smart Session & Context Isolation**: Supports distinct Project Profiles with isolated Session Maps, combined with auto-purge mechanisms (on sleep/lock) to ensure data never persists longer than necessary.

### Fail-safe Protocol (MVP Implementation)

*   **Strict Binary Success**: CodeMask will only re-hydrate tokens that are an **exact match** in the Session Map.
*   **Safe Fail State**: If any mismatch or token mangling is detected, CodeMask will halt hydration for that block, keeping the placeholders intact to prevent incorrect data exposure.
*   **User Recovery Path**: A non-intrusive "Safe Mode" alert will notify the user of the mismatch and provide a quick link to copy the original unmasked data for manual recovery.

### Market Context & Competitive Landscape

*   **Competitive Gap**: Current tools are either one-way sanitizers or general-purpose managers. CodeMask fills the niche for "Context-Aware AI Facilitation" specifically for mobile developers.

### Validation Approach

*   **Round-Trip Compiler Test**: Automated CI pipelines that mask a valid project file, pass it through a mock AI prompt, restore it, and verify that the final file is bit-for-bit identical to the original or compiles successfully in Xcode.

## Desktop App Specific Requirements

### Project-Type Overview
CodeMask is a native macOS application designed for system-wide clipboard interception and sanitization. By leveraging native Swift APIs, it ensures zero-latency performance and deep integration with the macOS environment, providing a seamless "security layer" for developers.

### Technical Architecture Considerations

*   **Native Swift Framework**: Utilization of Apple's `NSPasteboard` for clipboard monitoring and `Carbon`/`IOKit` for global hotkey registration to ensure maximum responsiveness (<100ms).
*   **Sandboxing & Permissions**: The app requires "Accessibility" and "Input Monitoring" permissions to capture system-wide shortcuts and detect active applications.
*   **In-Memory Lifecycle**: Implementation of a strict singleton-based session map that exists only in RAM, with auto-purge triggers on system sleep, lock, or 60-minute idle periods (monitored via lightweight event-driven timers).

### Guardian Mode (Background Monitoring)

*   **Passive Clipboard Observer**: A background listener that monitors `NSPasteboard` changes to perform "Passive Detection" without modifying content automatically.
*   **User Toggle**: Provides a Menu Bar toggle to switch between "Full Manual" and "Guardian Mode."
*   **Performance Guardrail (500KB Throttling)**: Background scans are bypassed for clipboard payloads > 500KB (~15k lines) to prevent UI jank. Manual masking via shortcut remains available for any size.

### Active Feedback System (HUD)

*   **Floating HUD Pill**: A non-interactive, semi-transparent "pill" UI that appears near the bottom of the active screen for immediate event feedback.
*   **Browser Context HUD**: A specialized alert triggered when the user switches focus to a web browser (e.g., Chrome, Safari) while the current clipboard contains unmasked sensitive information.
*   **Visual Status Indicators**:
    *   **Grey HUD**: Triggered when a payload is too large for a background scan (>500KB).
    *   **Yellow/Red HUD**: Triggered when unmasked secrets are detected.
    *   **Blue/Green HUD**: Confirmation of successful masking or restoration.
*   **Menu Bar Icon**: Provides permanent status feedback (Safe, Warning, Secured, Unknown/Grey).

### Security & Privacy

*   **Privacy Transparency**: Local-only logs showing which rules were matched (e.g., `Rule: AWS_KEY matched`) without displaying the actual sensitive content.
*   **Zero-Persistence Guarantee**: No session data is ever written to disk or transmitted over the network.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Experience MVP (Core "Magic" Focus)
**Resource Requirements:** 1-2 macOS Developers (Swift Specialist), 1 UX/UI Designer.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
*   Alex (The Sprinter): Zero-latency bidirectional flow.
*   Sarah (The Juggler): Multi-project profile isolation (Manual).
*   Marcus (The Guardian): HUD alerts and background monitoring.

**Must-Have Capabilities:**
*   Bidirectional Shortcut Engine (`Cmd+Opt+C/V`).
*   In-Memory Session Mapping with Auto-Purge.
*   Manual Project Profile Switching with Isolated Maps.
*   Per-Profile Regex Configuration.
*   Guardian Mode: Background Detection + HUD Feedback.
*   **Browser Context HUD**: Alert on browser switch with unmasked content.
*   Mobile Ecosystem Presets.

### Post-MVP Features

**Phase 2 (Growth):**
*   **Automatic Profile Awareness**: Auto-switch profile based on active window or file path.
*   **Visual Rule Editor**: A graphical interface for rule management.
*   **Full Browser Guard**: Browser extension for paste-interception.
*   **Local Telemetry Dashboard**: Enhanced statistics and usage insights.

**Phase 3 (Expansion):**
*   **Team Rule Synchronization**: Encrypted rule sharing for enterprise teams.
*   **AI Intelligent Detection**: Local LLM-based secret identification.

### Risk Mitigation Strategy

**Technical Risks:** The primary risk is the reliability of "Bidirectional Restoration" across varying AI model behaviors. Mitigation involves a robust **Fail-safe Protocol** that defaults to unmasked state rather than incorrect hydration.
**Market Risks:** User friction vs. safety. Mitigation involves the **Non-intrusive HUD design** and the "Experience MVP" approach to ensure CodeMask feels helpful, not hindering.
**Resource Risks:** Scoped specifically to **Native macOS** only to avoid cross-platform overhead and ensure maximum performance for the target audience.

## Functional Requirements

### 1. Secure Clipboard Operations (Core Engine)

*   **FR1**: Users can trigger a "Masking Copy" via a system-wide global shortcut.
*   **FR2**: System can identify sensitive patterns (e.g., API Keys, Bundle IDs) within clipboard content based on active rulesets.
*   **FR3**: System can replace identified sensitive patterns with deterministic placeholders (tokens).
*   **FR4**: System can maintain a local, in-memory mapping between placeholders and original sensitive data.
*   **FR5**: Users can trigger a "Re-hydration Paste" via a system-wide global shortcut.
*   **FR6**: System can restore original data into AI-generated code by matching deterministic placeholders against the session map.
*   **FR7**: System can perform a fail-safe check during restoration to prevent partial or incorrect data hydration.

### 2. Context & Profile Management

*   **FR8**: Users can create and manage multiple "Project Profiles."
*   **FR9**: Users can switch between active Project Profiles manually via global shortcuts or the Menu Bar.
*   **FR10**: System can isolate Session Maps between different Project Profiles to prevent cross-project data leakage.
*   **FR11**: Users can customize the Regex rulesets and filtering sensitivity per Project Profile.
*   **FR12**: System can import and export Project Profiles as JSON-based ruleset files.

### 3. Guardian Mode & Background Detection

*   **FR13**: Users can toggle "Guardian Mode" on or off via the Menu Bar.
*   **FR14**: System can perform passive, background scans of the system clipboard when Guardian Mode is active.
*   **FR15**: System can detect the active application context (e.g., if a web browser is focused).
*   **FR16**: System can bypass background scanning for clipboard payloads exceeding defined size thresholds, providing visual feedback for manual scanning.

### 4. User Feedback & HUD System

*   **FR17**: System can display a non-intrusive floating HUD "pill" for immediate event feedback (e.g., "Secured", "Mismatch Detected").
*   **FR18**: System can provide visual warnings in the Menu Bar icon based on the clipboard's current security state (Safe, Warning, Secured, Unknown).
*   **FR19**: System can alert users via a HUD when they switch to a browser focus while the clipboard contains unmasked sensitive data.
*   **FR20**: System can provide a manual recovery path (e.g., one-click copy of original data) when a fail-safe occurs.

### 5. Privacy, Security & Lifecycle

*   **FR21**: System can automatically purge all in-memory Session Maps upon system sleep or lock events (Default behavior, user configurable).
*   **FR22**: System can automatically purge Session Maps after a defined period of inactivity (User configurable duration).
*   **FR23**: Users can manually trigger a full memory purge ("Clear History") via the Menu Bar.
*   **FR24**: Users can view a local-only log of matched rules and security events without exposing the raw sensitive data.
*   **FR25**: System can operate 100% offline with zero external network dependencies for its core logic.
*   **FR26**: Users can customize security preferences, such as toggling auto-purge triggers and setting sensitive data retention limits.
*   **FR27**: System provides pre-configured regex templates for common mobile platform secrets (e.g., iOS Bundle IDs, Android Keystores).

## Non-Functional Requirements

### Performance
*   **P1 (Latency)**: Clipboard masking/restoration for payloads < 500KB must complete within **100ms (P95)**.
*   **P2 (CPU Efficiency)**: Background "Guardian Mode" monitoring must consume **< 1% average CPU** through smart polling of the system change count.
*   **P3 (UI Responsiveness)**: HUD pill alerts must trigger and display within **50ms** of the detection event.

### Security & Privacy
*   **S1 (Zero-Persistence)**: Use of **`mlock` (Memory Locking)** to prevent sensitive session data from being written to the disk's swap space.
*   **S2 (Local-only Architecture)**: Core logic must function with **zero external network requests**, ensuring data never leaves the local machine.
*   **S3 (Isolation)**: Logical memory isolation between Project Profiles to prevent cross-contamination of tokens.
*   **S4 (Secure Lifecycle)**: Automatic memory purge (clearing of all session maps) upon system sleep, screen lock, or a user-defined idle timeout.

### Reliability
*   **R1 (100% Deterministic Restoration)**: Any token re-hydration must be bit-for-bit accurate to the original data. Mismatches must trigger the fail-safe protocol rather than partial hydration.
*   **R2 (Data Integrity)**: The application must never corrupt the original clipboard content, even in the event of an internal crash.
*   **R3 (Stability)**: Zero memory leaks during 10,000+ consecutive clipboard change events.

### Usability
*   **U1 (Native DX)**: Adherence to macOS Human Interface Guidelines (HIG) for all UI elements (Menu Bar, HUD, Overlays).
*   **U2 (Accessibility)**: Clear onboarding flow and visual guidance for granting necessary macOS system permissions.
### Documentation & Polish

- **Visual Assets:** The repository must include high-quality visual assets (GIFs, Screenshots) in `/assets` to clearly demonstrate the Masking/Restoration workflow as per Epic 6.
- **User Guide:** Clear onboarding documentation must be provided in the README.
