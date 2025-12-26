---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments: []
workflowType: 'product-brief'
lastStep: 5
project_name: 'CodeMask'
user_name: 'Edison'
date: '2025-12-17'
---

# Product Brief: CodeMask

**Date:** 2025-12-17
**Author:** Edison

---

## Executive Summary

CodeMask is a native macOS utility designed to resolve the critical conflict between leveraging state-of-the-art Cloud AI (e.g., GPT-5, Claude 4.5) and maintaining strict data privacy for mobile development teams. By providing a frictionless, bidirectional "masking and re-hydration" layer, CodeMask allows iOS and Android developers to sanitize sensitive project data (such as Bundle IDs, Provisioning Profiles, and API Keys) before sending context to AI, and automatically restores that context upon return. It eliminates the trade-off between productivity and security, offering a lightweight, dependency-free solution tailored specifically for the mobile ecosystem.

---

## Core Vision

### Problem Statement

Mobile development teams face a "Efficiency vs. Privacy Dilemma." They are eager to utilize powerful cloud-based AI models to accelerate development but are paralyzed by the risk of leaking sensitive intellectual property (IP) and security credentials. Specific mobile-context data—such as App Bundle IDs, Team IDs, Keystores, and internal architectural fingerprints—identifies the company and project uniquely. Current options are unacceptable: either "run naked" and risk severe data leaks, or rely on slow, error-prone manual redaction that kills the development flow.

### Problem Impact

-   **Productivity Loss:** Developers are forced to forego AI assistance for complex tasks or waste significant time manually sanitizing code.
-   **Security Risk:** Human error in manual redaction leads to accidental exposure of API keys and proprietary logic.
-   **Competitive Disadvantage:** Teams unable to safely leverage SOTA AI models fall behind competitors who can (or who take the risk).

### Why Existing Solutions Fall Short

-   **Generic Masking Tools:** Lack awareness of mobile-specific formats (e.g., `embedded.mobileprovision`, `keystore` structures), missing critical identifiers.
-   **One-Way Filtering:** Existing tools often strip context permanently, requiring developers to manually re-integrate generic AI code back into their specific project structure.
-   **Heavy Dependencies:** Many solutions rely on heavy runtimes (like Python) which break the seamless "native" feel required by macOS-centric mobile developers.
-   **Native LLMs:** While private, they lack the reasoning capabilities of top-tier cloud models like GPT-5/Claude 4.5.

### Proposed Solution

CodeMask is a "Smart Translation Layer" between the developer's IDE and the AI.
1.  **Frictionless Workflow:** A global shortcut (`Cmd+Opt+C`) captures, sanitizes, and prepares code for the AI.
2.  **Bidirectional Re-hydration:** Unlike simple filters, CodeMask maps sensitive data to generic placeholders (e.g., `{{BUNDLE_ID}}`) and, upon receiving the AI's response, intelligently "re-hydrates" the code back to its original context.
3.  **Native Architecture:** A lightweight, Swift-based application utilizing the native Regex engine for maximum performance and zero environment overhead.

### Key Differentiators

-   **Bidirectional Context Awareness:** The ability to restore specific project context (IP) into generic AI suggestions automatically.
-   **Mobile Ecosystem Specialization:** Out-of-the-box recognition of iOS/Android specific sensitive patterns that generic tools miss.
-   **Native DX (Developer Experience):** No heavy dependencies (Python/Node); pure macOS native performance.
-   **Flow Preservation:** Designed to integrate into the copy-paste loop without breaking the developer's mental state.

---

## Target Users

### Primary Users

#### 1. The Sprinter (Efficiency-First Developer)
*   **Role:** Mid-to-Senior iOS/Android Developer working on a single core product.
*   **Motivation:** Velocity. Wants to stay in the "flow state" while coding.
*   **Pain Point:** Wants to paste a complex View Controller into Claude for refactoring but hesitates because scrubbing the Bundle IDs and API keys manually takes 2 minutes and breaks their focus.
*   **Key Interaction:** Relies almost exclusively on the Global Shortcut (`Cmd+Opt+C`). Expects near-instant feedback (~100ms). Rarely opens the main configuration UI.
*   **Success Logic:** "I hit the hotkey, pasted into AI, got the fix, and pasted it back. It just worked."

#### 2. The Juggler (Agency/Freelance Developer)
*   **Role:** Mobile Developer managing 3+ distinct client projects simultaneously.
*   **Motivation:** Accuracy and Context Switching. Needs to ensure Client A's secrets never leak, and Client B's context is never applied to Client A's code.
*   **Pain Point:** Accidentally revealing Client A's Bundle ID in a prompt about Client B's bug. Dealing with different naming conventions per project.
*   **Key Interaction:** Heavily utilizes **Project Profiles**. Switches active profiles via the Menu Bar or Shortcut before masking.
*   **Success Logic:** "I switched to the 'FinTech App' profile, and CodeMask knew exactly which custom headers to strip."

#### 3. The Guardian (Security-Conscious/Enterprise Dev)
*   **Role:** Developer in a regulated industry (Banking, Healthcare) or large enterprise.
*   **Motivation:** Compliance and Anxiety Reduction. Terrified of the "one slip-up" that gets them fired.
*   **Pain Point:** The constant low-level stress of "Did I miss a key?" when using AI.
*   **Key Interaction:** Relies on **Browser Guard** (Safety Net) and **Debug Mode**. Checks the "Diff View" or "Replacements Log" to verify exactly what was masked before sending.
*   **Success Logic:** "I saw the red warning flash when I tried to copy a private key, and CodeMask blocked it. I feel safe."

### Secondary Users

#### The Rule Maker (Tech Lead / Architect)
*   **Role:** Senior Lead responsible for team standards and security practices.
*   **Goal:** Enforce consistent security policies across the team without slowing them down.
*   **Key Interaction:** **Configuration Management**. Spends time crafting robust Regex rules (e.g., matching internal specific headers) and uses **Import/Export** to distribute these "Masking Rulesets" to the junior team members (Sprinters).
*   **Value:** "I sent the `team-security-config.json` to the team, and now I know everyone is stripping our internal API headers correctly."

### User Journey

#### The "Flow State" Loop (Primary Journey)
1.  **Trigger:** Developer encounters a complex bug in Xcode/Android Studio.
2.  **Action:** Selects the code block and hits `Cmd+Opt+C`.
3.  **System Response:** CodeMask runs in the background.
    *   **Feedback:** A subtle sound or Menu Bar icon flash indicates "Secured."
    *   **Clipboard:** Original code is replaced with the Masked Version (e.g., `{{BUNDLE_ID}}`).
4.  **AI Interaction:** Developer pastes into ChatGPT/Claude.
5.  **Return:** Developer copies the AI's fix.
6.  **Re-hydration:** Developer hits `Cmd+Opt+V` (or uses the clipboard manager) to paste back into IDE. CodeMask automatically restores the original IDs into the new code.
7.  **Result:** Bug fixed, no secrets leaked, zero friction.

---

## Success Metrics

### User Success Metrics (The "Aha!" Moments)

#### 1. The "Saved You" Metric (Risk Mitigation)
*   **Definition:** The number of times CodeMask actively intercepts and masks a verified sensitive pattern (e.g., `AWS_SECRET_KEY`, `Bundle ID`) that was about to be pasted into an external context.
*   **User Value:** Represents specific "near-miss" security incidents prevented.
*   **Target Outcome:** Users see a "Secrets Protected: 50+" stat on their local dashboard within the first month, reinforcing the feeling of safety.

#### 2. The "Magic Restore" Metric (Efficiency Gain)
*   **Definition:** The frequency of using the "Re-hydrate" (`Cmd+Opt+V`) feature to successfully restore context to AI-generated code.
*   **User Value:** Quantifies the time saved from manual "Find & Replace" drudgery.
*   **Target Outcome:** Users establish a "Closed Loop" workflow where for every 3 "Masking" actions, there is at least 1 "Restore" action, indicating deep integration into the coding cycle.

#### 3. Muscle Memory Adoption
*   **Definition:** The ratio of `Cmd+Opt+C` (CodeMask Copy) usage versus standard `Cmd+C` when the IDE is the active window.
*   **User Value:** Indicates that CodeMask has replaced the default behavior for coding tasks.
*   **Target Outcome:** >50% of clipboard operations from IDEs are triggered via CodeMask shortcuts within 2 weeks of installation.

### Business Objectives

#### 1. Trust & Penetration in the Mobile Dev Niche
*   **Objective:** Establish CodeMask as the standard "Compliance Enabler" for iOS/Android teams.
*   **Indicator:** Adoption by "Guardian" persona users (Enterprise/Regulated sectors).

#### 2. Workflow Stickiness
*   **Objective:** Become an indispensable part of the development loop, not just a "sometimes" utility.
*   **Indicator:** High retention rates for the "Re-hydration" feature. If users mask but don't restore, we are just a sanitizer; if they restore, we are a workflow enhancer.

### Key Performance Indicators (KPIs)

#### Product Performance
*   **Masking Latency:** < 100ms (P95). Speed is the primary feature for "The Sprinter."
*   **False Positive Rate:** < 1% of non-sensitive variables masked (to prevent AI confusion).
*   **Restore Accuracy:** 100% deterministic restoration of tokens (Trust is binary; one bad restore breaks trust).

#### Growth & Engagement (Local Stats Telemetry*)
*   *Note: CodeMask is privacy-first. These are metrics displayed LOCALLY to the user to prove value, or opt-in anonymous telemetry.*
*   **Secrets Shielded Count:** Total sensitive items masked per user per week.
*   **Time Saved:** Calculated as `(Re-hydrations * 2 mins) + (Masks * 1 min)`.
*   **Profile Utilization:** % of users with >1 Active Profile (validating "The Juggler" use case).

---

## MVP Scope

### Core Features (The "Reliable Clipboard Converter")

#### 1. Bidirectional Shortcut Engine
*   **Masking (`Cmd+Opt+C`):** Captures selection, applies Regex replacements, copies result to clipboard. **Customizable.**
*   **Re-hydration (`Cmd+Opt+V`):** Reads clipboard, restores original values from the session map, pastes result into active window. **Customizable.**
*   **Latency Target:** < 100ms processing time.

#### 2. Mobile-Optimized Preset Ruleset
*   **iOS Pack:** Pre-configured Regex for Bundle IDs (`com.company.app`), Team IDs (10-char alphanum), Provisioning Profile UUIDs.
*   **Android Pack:** Pre-configured Regex for Keystore paths, Gradle signing configs, Google Services API keys.
*   **User Action:** "One-click enable" for these packs during onboarding.

#### 3. Basic Project Profile Management
*   **Profile Switcher:** Simple Menu Bar dropdown to select active context (e.g., "Project A" vs "Project B").
*   **JSON Config:** Ability to edit rules and variable mappings (e.g., `REAL_ID` -> `MASKED_TOKEN`) via a simple UI or by editing a local JSON file.

#### 4. Local Telemetry Dashboard
*   **Stats View:** Simple counter showing "Secrets Masked" and "Time Saved" to reinforce value.

### Out of Scope for MVP (The "Nice-to-Haves")

*   **Browser Guard (Safety Net):** No active browser URL monitoring or injection. Reliance is 100% on user intent (shortcuts).
*   **AI/NLP Detection:** No usage of ML models (like Presidio) for PII detection. Pure Regex only.
*   **Cloud Sync/Team Accounts:** No backend. Configuration sharing is done via manual JSON file export/import.
*   **Advanced Visual Editor:** No complex drag-and-drop rule builders. Text-based configuration is sufficient for MVP.
*   **Sound Effects/Animations:** Visual feedback will be limited to Menu Bar icon state changes.

### MVP Success Criteria

#### 1. The "It Compiles" Test
*   **Validation:** A developer can mask a `AppDelegate.swift` file, ask ChatGPT to refactor it, restore the result, and build the project successfully without manual syntax correction.

#### 2. Performance Benchmark
*   **Validation:** The `Cmd+Opt+C` action must complete (from keypress to clipboard update) in under 100ms on an M1 MacBook Air.

#### 3. Zero-Crash Stability
*   **Validation:** No app crashes during 100 consecutive mask/restore cycles.

### Future Vision

*   **Phase 2 (The Safety Net):** Browser Guard integration to catch accidental pastes (Ctrl+V) of sensitive data in web browsers.
*   **Phase 3 (Team Sync):** Encrypted iCloud/CloudKit sync for sharing profiles across a team.
*   **Phase 4 (Intelligent Scanning):** Optional local LLM integration to detect non-pattern-based secrets (e.g., hardcoded passwords in comments).
