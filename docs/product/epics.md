---
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
project_name: 'CodeMask'
user_name: 'Edison'
date: '2025-12-24'
---

# CodeMask - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for CodeMask, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Users can trigger a "Masking Copy" via a system-wide global shortcut.
FR2: System can identify sensitive patterns (e.g., API Keys, Bundle IDs) within clipboard content based on active rulesets.
FR3: System can replace identified sensitive patterns with deterministic placeholders (tokens).
FR4: System can maintain a local, in-memory mapping between placeholders and original sensitive data.
FR5: Users can trigger a "Re-hydration Paste" via a system-wide global shortcut.
FR6: System can restore original data into AI-generated code by matching deterministic placeholders against the session map.
FR7: System can perform a fail-safe check during restoration to prevent partial or incorrect data hydration.
FR8: Users can create and manage multiple "Project Profiles."
FR9: Users can switch between active Project Profiles manually via global shortcuts or the Menu Bar.
FR10: System can isolate Session Maps between different Project Profiles to prevent cross-project data leakage.
FR11: Users can customize the Regex rulesets and filtering sensitivity per Project Profile.
FR12: System can import and export Project Profiles as JSON-based ruleset files.
FR13: Users can toggle "Guardian Mode" on or off via the Menu Bar.
FR14: System can perform passive, background scans of the system clipboard when Guardian Mode is active.
FR15: System can detect the active application context (e.g., if a web browser is focused).
FR16: System can bypass background scanning for clipboard payloads exceeding defined size thresholds, providing visual feedback for manual scanning.
FR17: System can display a non-intrusive floating HUD "pill" for immediate event feedback (e.g., "Secured", "Mismatch Detected").
FR18: System can provide visual warnings in the Menu Bar icon based on the clipboard's current security state (Safe, Warning, Secured, Unknown).
FR19: System can alert users via a HUD when they switch to a browser focus while the clipboard contains unmasked sensitive data.
FR20: System can provide a manual recovery path (e.g., one-click copy of original data) when a fail-safe occurs.
FR21: System can automatically purge all in-memory Session Maps upon system sleep or lock events (Default behavior, user configurable).
FR22: System can automatically purge Session Maps after a defined period of inactivity (User configurable duration).
FR23: Users can manually trigger a full memory purge ("Clear History") via the Menu Bar.
FR24: Users can view a local-only log of matched rules and security events without exposing the raw sensitive data.
FR25: System can operate 100% offline with zero external network dependencies for its core logic.
FR26: Users can customize security preferences, such as toggling auto-purge triggers and setting sensitive data retention limits.
FR27: System provides pre-configured regex templates for common mobile platform secrets (e.g., iOS Bundle IDs, Android Keystores).

### NonFunctional Requirements

NFR1: Clipboard masking/restoration for payloads < 500KB must complete within 100ms (P95).
NFR2: Background "Guardian Mode" monitoring must consume < 1% average CPU through smart polling of the system change count.
NFR3: HUD pill alerts must trigger and display within 50ms of the detection event.
NFR4: Use of mlock (Memory Locking) to prevent sensitive session data from being written to the disk's swap space.
NFR5: Core logic must function with zero external network requests, ensuring data never leaves the local machine.
NFR6: Logical memory isolation between Project Profiles to prevent cross-contamination of tokens.
NFR7: Automatic memory purge (clearing of all session maps) upon system sleep, screen lock, or a user-defined idle timeout.
NFR8: Any token re-hydration must be bit-for-bit accurate to the original data. Mismatches must trigger the fail-safe protocol rather than partial hydration.
NFR9: The application must never corrupt the original clipboard content, even in the event of an internal crash.
NFR10: Zero memory leaks during 10,000+ consecutive clipboard change events.
NFR11: Adherence to macOS Human Interface Guidelines (HIG) for all UI elements (Menu Bar, HUD, Overlays).
NFR12: Clear onboarding flow and visual guidance for granting necessary macOS system permissions.

### Additional Requirements

- **Starter Template:** Custom Native Scaffolding (Swift/SwiftUI/AppKit). Manual Xcode Project setup targeting macOS 26 (AppKit life cycle with SwiftUI Views).
- **Architecture Pattern:** Native Unidirectional Flow using Swift 6.2 Actors and @Observable.
- **State Management:** Actor-isolated `SessionActor` for thread-safe, logical isolation of project sessions.
- **Testing:** XCTest with Protocol-Oriented Mocking for zero-dependency reliability.
- **Regex Engine:** Swift 5.7+ Native `Regex` for sub-100ms performance and type-safety.
- **Persistence:** Local JSON files in `Application Support` for rule and profile management (supporting Import/Export).
- **Communication:** Unidirectional Store Actions for consistent state updates across Menu Bar and HUD.
- **Security:** Direct memory locking (`mlock`) via `UnsafeMutableRawPointer`.
- **UI Framework:** SwiftUI for Views + AppKit for Window Management (`NSPanel`).
- **Project Structure:** Feature-First organization (`Features/Clipboard`, `Features/Session`, etc.).
- **Conflated Task Pattern:** For `ClipboardMonitor` to prevent race conditions.
- **HUD Style:** A floating pill/capsule with `NSVisualEffectView` (.hudWindow material) and a subtle system shadow.
- **HUD Animation:** Snappy, high-velocity "Slide In" from the top or bottom of the screen with a 200ms ease-out fade.
- **Typography:** SF Pro Rounded for status labels, SF Mono for technical data tokens.
- **Feedback:** Triple-Channel feedback system (Visual, Audio, Haptic).
- **Accessibility:** Non-activating panel to avoid stealing keyboard input; VoiceOver support; High Contrast support.

### FR Coverage Map

FR1: Epic 1 - Trigger a "Masking Copy" via a system-wide global shortcut.
FR2: Epic 1 - Identify sensitive patterns within clipboard content.
FR3: Epic 1 - Replace sensitive patterns with deterministic placeholders.
FR4: Epic 1 - Maintain a local, in-memory mapping of placeholders.
FR5: Epic 1 - Trigger a "Re-hydration Paste" via a system-wide global shortcut.
FR6: Epic 1 - Restore original data into AI-generated code.
FR7: Epic 1 - Perform a fail-safe check during restoration.
FR8: Epic 3 - Create and manage multiple "Project Profiles."
FR9: Epic 3 - Switch between active Project Profiles.
FR10: Epic 3 - Isolate Session Maps between different Project Profiles.
FR11: Epic 3 - Customize the Regex rulesets per Project Profile.
FR12: Epic 3 - Import and export Project Profiles as JSON.
FR13: Epic 2 - Toggle "Guardian Mode" on or off.
FR14: Epic 2 - Perform passive, background scans of the system clipboard.
FR15: Epic 2 - Detect the active application context.
FR16: Epic 2 - Bypass background scanning for large payloads.
FR17: Epic 2 - Display a non-intrusive floating HUD "pill".
FR18: Epic 2 - Provide visual warnings in the Menu Bar icon.
FR19: Epic 2 - Alert users when switching to a browser.
FR20: Epic 2 - Provide a manual recovery path on fail-safe.
FR21: Epic 4 - Automatically purge Session Maps on system sleep or lock.
FR22: Epic 4 - Automatically purge Session Maps after inactivity.
FR23: Epic 4 - Manually trigger a full memory purge.
FR24: Epic 4 - View a local-only log of matched rules.
FR25: Epic 1 - Operate 100% offline.
FR26: Epic 4 - Customize security preferences.
FR27: Epic 1 - Provide pre-configured regex templates.
NFR1: Epic 1 - Performance: Mask/restore latency < 100ms.
NFR2: Epic 2 - Performance: Guardian Mode CPU < 1%.
NFR3: Epic 2 - Performance: HUD display latency < 50ms.
NFR4: Epic 1 - Security: Use mlock to prevent disk swap.
NFR5: Epic 1 - Security: Local-only architecture.
NFR6: Epic 3 - Security: Profile memory isolation.
NFR7: Epic 4 - Security: Automatic memory purge.
NFR8: Epic 1 - Reliability: 100% deterministic restoration.
NFR9: Epic 1 - Reliability: Never corrupt original clipboard.
NFR10: Epic 1 - Reliability: Zero memory leaks.
NFR11: Epic 2 - Usability: Adherence to macOS HIG.
NFR12: Epic 5 - Usability: Clear onboarding and permissioning.

## Epic List

## Epic 1: The Secure Clipboard Engine

**Goal:** Establish the core "Masking and Restoration" capability with zero persistence. This allows the "Sprinter" user to start using the basic copy-paste loop immediately.

### Story 1.1: Core App & Permissions Scaffolding

As a developer,
I want a native macOS application structure with necessary system permissions,
So that the app can run securely in the background and access the system clipboard and shortcuts.

**Acceptance Criteria:**

**Given** the project is initialized with custom native scaffolding
**When** the application is launched
**Then** it should appear only as a Menu Bar extra (no Dock icon)
**And** it should proactively request "Accessibility" and "Input Monitoring" permissions
**And** it should display a "Safe" (Grey/Blue) status in the Menu Bar if permissions are granted.

### Story 1.2: Global Hotkey Manager

As a user,
I want to use system-wide shortcuts (Cmd+Opt+C and Cmd+Opt+V),
So that I can trigger masking and restoration from any application without switching focus.

**Acceptance Criteria:**

**Given** the application is running in the background
**When** I press `Cmd+Opt+C`
**Then** the application should intercept the event and trigger the masking sequence
**When** I press `Cmd+Opt+V`
**Then** the application should intercept the event and trigger the restoration sequence
**And** these shortcuts must work regardless of the active application (Xcode, Browser, Slack).

### Story 1.3: In-Memory Session Storage (Secure)

As a security-conscious developer,
I want my sensitive data to be stored strictly in RAM and protected from disk swap,
So that no trace of my secrets is ever written to persistent storage.

**Acceptance Criteria:**

**Given** a secret string is captured during masking
**When** the `SessionActor` stores the data
**Then** it must use `mlock` via `UnsafeMutableRawPointer` to prevent the memory from being swapped to disk
**And** the data must be associated with a unique, high-entropy token (e.g., UUID-based)
**And** all stored data must be logically isolated within the current session.

### Story 1.4: Basic Masking Engine (Regex)

As a user,
I want the system to automatically detect and replace sensitive patterns in my clipboard,
So that I don't accidentally share secrets with AI models.

**Acceptance Criteria:**

**Given** a block of text containing sensitive patterns (e.g., "DBS", Emails, IPs)
**When** the masking engine processes the text
**Then** it should identify the patterns using native Swift Regex
**And** replace them with high-entropy, UUID-based tokens (e.g., `{{CM_TOKEN_A1B2...}}`) to prevent collision or guessing
**And** the engine must handle word boundaries correctly (e.g., matching "DBS" but not "DATABASE")
**And** in case of overlapping matches, it must prioritize the "Longest Match First" to ensure complete protection.

### Story 1.5: The Masking Loop (Copy)

As a user,
I want the "Masking Copy" action to be seamless and fast,
So that my development flow is not interrupted.

**Acceptance Criteria:**

**Given** I have selected text in an IDE
**When** I press `Cmd+Opt+C`
**Then** the original text is read from `NSPasteboard`
**And** the masked version is generated in <100ms
**And** the masked version is written back to `NSPasteboard`
**And** the original version is stored securely in the `SessionActor`.

### Story 1.6: The Restoration Loop (Paste)

As a user,
I want the "Re-hydration Paste" action to restore my original secrets into AI-generated code,
So that I don't have to manually find and replace placeholders.

**Acceptance Criteria:**

**Given** the clipboard contains text with `{{CM_TOKEN_N}}` placeholders
**When** I press `Cmd+Opt+V`
**Then** the system should identify all tokens
**And** lookup the original values in the `SessionActor`
**And** replace the tokens with original values bit-for-bit
**And** paste the final result into the active application using Accessibility APIs
**And** if automated pasting fails, it must fallback to copying the restored content to the clipboard and notifying the user to paste manually
**And** if a token is missing, it should use the fail-safe marker `>>MISSING_SECRET<<`.

### Story 1.7: Mobile Presets & Advanced Regex

As a mobile developer,
I want built-in support for iOS and Android secrets,
So that I am protected out of the box without complex configuration.

**Acceptance Criteria:**

**Given** a new installation of CodeMask
**When** I use the default profile
**Then** it should include regex patterns for iOS Bundle IDs, Team IDs, Android Keystores, and Gradle signing configs
**And** these patterns must be optimized for performance to ensure the <100ms latency requirement.

## Epic 2: Visual Feedback & Guardian Mode

**Goal:** Provide the "Guardian" user with visual proof of security and background monitoring.

**Recommended Implementation Order (Based on Story 2.0 Spike Findings):**

1. **Story 2.0** - Technical Spikes & Research ✅ (Complete)
2. **Story 2.1** - Menu Bar Status Icon (No dependencies, foundational UI)
3. **Story 2.4** - Browser Context Detection (Standalone, spike-validated)
4. **Story 2.3** - Guardian Mode (Depends on 2.4 for browser context awareness)
5. **Story 2.5** - Browser Guard Alert (Depends on 2.3 + 2.4)
6. **Story 2.2** - Dynamic Pill HUD (Depends on 2.5 for alert patterns, polish step)
7. **Story 2.6** - Triple-Channel Feedback (Depends on 2.2, final polish)
8. **Story 2.7** - Large Payload Bypass (Depends on 2.2 + 2.3)

**Rationale:** Build browser detection first, then Guardian Mode monitoring, then alerts, then polish HUD and feedback systems.

**Reference:** See `docs/research/epic-2-spikes.md` for detailed technical validation.

### Story 2.0: Technical Spikes & Research
 
 As a developer,
 I want to validate critical technical assumptions before implementation,
 So that I don't build features based on incorrect system behavior understandings.
 
 **Acceptance Criteria:**
 
 **Given** the "Browser Detection" requirement (Story 2.4/2.5)
 **When** I run the Spike
 **Then** I must confirm `NSWorkspace` can detect the active browser window with <50ms latency
 **And** verify if explicit `Privacy Usage Descriptions` are required for this API.
 
 **Given** the "Clipboard Race Condition" risk (Story 2.3)
 **When** I conduct the research
 **Then** I must identify if macOS allows detecting external clipboard reads (Anti-Spyware)
 **And** document findings to inform the "Guardian Mode" implementation strategy.
 
 ### Story 2.1: Menu Bar Status Icon

As a user,
I want to know the security status of my session at a glance,
So that I can verify if I have sensitive data stored in memory or if there are potential risks.

**Acceptance Criteria:**

**Given** the application is running
**When** the session map is empty
**Then** the Menu Bar icon should be Grey (Idle)
**When** the session map contains secure data
**Then** the Menu Bar icon should be Blue (Secured)
**When** a browser is focused while unmasked secrets are in clipboard
**Then** the Menu Bar icon should flash Red (Warning).

### Story 2.2: Dynamic Pill HUD (Success/Feedback)

As a "Sprinter" user,
I want immediate, non-intrusive feedback when I trigger masking or restoration,
So that I know the action succeeded without having to check the clipboard content manually.

**Acceptance Criteria:**

**Given** I trigger a global shortcut
**When** the action completes successfully
**Then** a floating "Pill" HUD should appear within 50ms
**And** it should display the action state (e.g., "Secured", "Restored") with a relevant SF Symbol
**And** it must NOT steal keyboard focus from the active application
**And** it should automatically fade out after a short duration.

### Story 2.3: Guardian Mode: Passive Clipboard Monitor

As a user,
I want the app to passively monitor my clipboard in the background,
So that it knows when I have copied sensitive data and can proactively protect me from accidental exposure.

**Acceptance Criteria:**

**Given** "Guardian Mode" is enabled in settings
**When** the system clipboard content changes (detected via `NSPasteboard.changeCount`)
**Then** the background monitor should detect the change within 500ms
**And** it should scan the content against active regex rules using <1% CPU
**And** it should update the internal state to "Danger" if unmasked secrets are found
**And** it should mark clipboard data with transient marker (`org.nspasteboard.TransientType`) to reduce persistence in clipboard managers.

**Note:** macOS does not provide APIs to detect external clipboard *reads*. Guardian Mode provides proactive protection by monitoring clipboard *writes* and context switching (see Story 2.4/2.5).

**Technical Reference:** See `docs/research/epic-2-spikes.md` (Story 2.0) for clipboard security research findings, transient marker validation, and changeCount polling pattern.

### Story 2.4: Browser Context Detection

As a system,
I need to know when the user switches to a web browser,
So that I can determine if a security warning is necessary.

**Acceptance Criteria:**

**Given** the user is navigating their OS
**When** the active application window changes
**Then** the system should detect the new frontmost application
**And** identify if it is a known browser (Chrome, Safari, Firefox, Arc, etc.)
**And** this check must be lightweight and privacy-preserving.

**Technical Reference:** See `docs/research/epic-2-spikes.md` (Story 2.0) for NSWorkspace API validation, Bundle ID verification, and latency characteristics.

### Story 2.5: Browser Guard & Alert HUD

As a "Guardian" user,
I want to be warned if I'm about to paste unmasked secrets into a browser,
So that I can prevent accidental data leaks to web-based AI tools.

**Acceptance Criteria:**

**Given** the clipboard contains unmasked sensitive patterns
**When** I switch focus to a web browser window
**Then** a Red "Danger" HUD should appear immediately
**And** it should warn "Unmasked Secrets Detected"
**And** the Menu Bar icon should switch to the Warning state.

**Technical Reference:** See `docs/research/epic-2-spikes.md` (Story 2.0) for browser detection latency validation and recommended response time budget.

### Story 2.6: Triple-Channel Feedback (Audio & Haptic)

As a user,
I want tactile and audible confirmation of security actions,
So that I can trust the system without looking at the screen.

**Acceptance Criteria:**

**Given** a masking or restoration action is triggered
**When** the operation succeeds
**Then** play a subtle system sound ("Tink")
**And** trigger a generic haptic feedback on the trackpad
**And** if an error occurs (e.g., Browser Warning), play a warning sound ("Thump") and trigger a stronger haptic alignment pattern.

### Story 2.7: Large Payload Bypass & Feedback

As a user,
I want the system to remain responsive even when I copy massive text blocks,
So that my computer doesn't freeze.

**Acceptance Criteria:**

**Given** I copy a text block larger than 500KB
**When** the background monitor attempts to scan
**Then** it should bypass the regex analysis
**And** show a Grey HUD indicating "Payload too large for auto-scan"
**And** allow me to manually trigger masking via the shortcut if needed.

## Epic 3: Profile Management & Context Isolation

**Goal:** Enable the "Juggler" user to manage multiple client contexts without leakage.

### Story 3.1: Profile Data Model & Persistence

As a system,
I want a robust data structure for Project Profiles,
So that users can save and load their custom security configurations reliably.

**Acceptance Criteria:**

**Given** the application is running
**When** a new profile is created
**Then** it should be saved as a JSON file in the `Application Support` directory
**And** it must contain the profile name, unique ID, and an array of Regex rules
**And** all persistence logic must be handled by a dedicated `ProfileManager`.

### Story 3.2: Profile Management UI (Settings)

As a user,
I want a clean interface to manage my projects,
So that I can easily organize different client security requirements.

**Acceptance Criteria:**

**Given** the Preferences window is open
**When** I navigate to the "Profiles" tab
**Then** I should see a list of existing profiles
**And** I should be able to create a new profile, rename an existing one, or delete a profile
**And** the UI must follow macOS native sidebar/detail pattern.

### Story 3.3: Custom Regex Rules Editor

As a "Rule Maker,"
I want to define specific words or patterns to be masked for each project,
So that I can protect proprietary terms like "DBS" or "InternalProjectName".

**Acceptance Criteria:**

**Given** a specific Project Profile is selected
**When** I add a new Regex rule
**Then** I should be able to input a pattern (e.g., `\bDBS\b`) and a placeholder name
**And** the system should validate that the Regex is syntactically correct
**And** I should see a "Live Preview" of how the token will look.

### Story 3.4: Profile Switching Logic & Isolation

As a security-conscious user,
I want strict isolation between different project sessions,
So that I never accidentally restore "Client A" secrets into "Client B" code.

**Acceptance Criteria:**

**Given** I am switching from Profile A to Profile B
**When** the active profile changes
**Then** the system must swap the active `SessionActor` instance to the one corresponding to Profile B
**And** the memory for Profile A's actor must be secured (purged or locked in background)
**And** any attempt to resolve a token from Profile A must fail immediately at the actor level
**And** this switch must be atomic to prevent race conditions.

### Story 3.5: Profile Switcher HUD (Cmd+Ctrl+P)

As a "Juggler" user,
I want to switch project contexts quickly using my keyboard,
So that I don't break my focus when moving between different tasks.

**Acceptance Criteria:**

**Given** I am working in any application
**When** I press `Cmd+Ctrl+P`
**Then** a non-activating HUD list of all profiles should appear
**And** I should be able to cycle through them using arrow keys or repeated hotkey presses
**And** pressing `Enter` should activate the selected profile and show a "Switched to [Profile Name]" confirmation HUD.

### Story 3.6: Import/Export Profiles (JSON)

As a tech lead,
I want to share my regex rulesets with my team,
So that we all have consistent security protection for the same project.

**Acceptance Criteria:**

**Given** a profile with complex rules
**When** I select "Export Profile"
**Then** the system should generate a shareable `.json` file containing the ruleset (excluding session data)
**When** another user imports this file
**Then** it should appear as a new Project Profile in their application instantly.

## Epic 4: Lifecycle & Privacy Management

**Goal:** Automate security hygiene and provide transparency for the "Rule Maker."

### Story 4.1: Auto-Purge on System Events

As a security-conscious user,
I want the app to automatically clear its memory when my computer sleeps or locks,
So that no data persists when I'm away from my machine.

**Acceptance Criteria:**

**Given** the application contains sensitive session data
**When** the macOS system sends a Sleep or Screen Lock notification
**Then** the `SessionActor` must immediately purge all mapped data from RAM
**And** the Menu Bar icon must update to the Grey (Idle) state.

### Story 4.2: Idle Timeout Purge

As a user,
I want my session to expire after a period of inactivity,
So that I don't accidentally leave secrets in memory overnight.

**Acceptance Criteria:**

**Given** I have enabled "Auto-Purge after Inactivity" in settings
**When** the configured duration (e.g., 60 mins) passes without any clipboard masking/restoration activity
**Then** the system should automatically trigger a full session purge
**And** a notification/HUD should inform me "Session Expired due to Inactivity".

### Story 4.3: Manual "Clear History" Action

As a user,
I want to manually wipe all sensitive data instantly,
So that I can feel secure before sharing my screen or handing over my laptop.

**Acceptance Criteria:**

**Given** the Menu Bar application is active
**When** I select "Clear History" from the menu
**Then** all in-memory session maps must be securely deallocated immediately
**And** I should receive a haptic and visual confirmation ("History Cleared").

### Story 4.4: Local Security Audit Log (Masked)

As a "Rule Maker" or auditor,
I want to see a log of what security rules have been triggered,
So that I can verify the tool is working without exposing the actual secrets.

**Acceptance Criteria:**

**Given** masking events have occurred
**When** I view the "Security Log" in Settings
**Then** I should see a list of events with timestamps and rule names (e.g., "10:00 AM - AWS Key Rule Matched")
**But** the log must NEVER contain the actual masked content or the original secret
**And** this log file must be stored locally and accessible only to the user.

### Story 4.5: Security Preferences UI

As a user,
I want to customize my security thresholds,
So that I can balance convenience with protection.

**Acceptance Criteria:**

**Given** I am in the Preferences > Security tab
**Then** I should be able to toggle "Purge on Sleep", "Purge on Lock", and set the "Idle Timeout" duration
**And** I should be able to view or clear the Local Audit Log.

## Epic 5: First-Run Experience & Permissioning

**Goal:** Ensure a smooth onboarding for all users, handling the critical macOS permissions.

### Story 5.1: Onboarding Window

As a new user,
I want to see a welcoming introduction to CodeMask,
So that I understand its core value and how it fits into my workflow.

**Acceptance Criteria:**

**Given** the application is launched for the first time
**When** the app starts
**Then** it should display a non-intrusive onboarding window
**And** it should briefly explain the "Secure Copy-Paste Loop" and the "Mask/Restore" shortcuts
**And** it should guide the user to the permission granting step.

### Story 5.2: Permission Granting Flow

As a user,
I want a clear guide on how to grant necessary macOS permissions,
So that I don't get frustrated by system security prompts.

**Acceptance Criteria:**

**Given** the application requires Accessibility and Input Monitoring permissions
**When** I am in the onboarding flow
**Then** I should see a button that opens the System Settings to the correct Privacy & Security tab
**And** the UI should provide visual instructions (e.g., "Find CodeMask and toggle the switch")
**And** the app should automatically detect when permissions are granted and proceed to the next step.

### Story 5.3: "Ready to Go" Tutorial

As a user,
I want to verify that the app is working correctly after setup,
So that I can start using it with confidence.

**Acceptance Criteria:**

**Given** all permissions have been granted
**When** I reach the final onboarding screen
**Then** it should provide a "Try it now" text box
**And** it should prompt me to use `Cmd+Opt+C` and `Cmd+Opt+V` to see the masking/restoration in action
**And** upon successful test, it should show a "You're all set!" message and move to the Menu Bar.
