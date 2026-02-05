# Story 2.0: Technical Spikes & Research

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want to validate critical technical assumptions before implementation,
so that I don't build features based on incorrect system behavior understandings.

## Acceptance Criteria

1. **Given** the "Browser Detection" requirement (Story 2.4/2.5)  
   **When** I run the Spike  
   **Then** I must confirm `NSWorkspace` can detect the active browser window with < 50ms latency  
   **And** verify if explicit `Privacy Usage Descriptions` are required for this API.
2. **Given** the "Clipboard Race Condition" risk (Story 2.3)  
   **When** I conduct the research  
   **Then** I must identify if macOS allows detecting external clipboard reads (Anti-Spyware)  
   **And** document findings to inform the "Guardian Mode" implementation strategy.

## Tasks / Subtasks

- [ ] Task 1: Browser Detection Spike (AC: 1)
  - [ ] Implement a prototype using `NSWorkspaceDidActivateApplicationNotification` to track frontmost application.
  - [ ] Measure latency between application switch and detection.
  - [ ] Test with major browsers (Safari, Chrome, Firefox, Arc) using bundle identifiers.
  - [ ] Verify if `NSPrivacyAccessedAPITypes` or `Info.plist` usage descriptions are required for `NSWorkspace.shared.frontmostApplication`.
- [ ] Task 2: Clipboard Security Research (AC: 2)
  - [ ] Investigate `NSPasteboard` APIs for any "access" callbacks or ownership tracking beyond `changeCount`.
  - [ ] Research "Clipboard Stealth" techniques (e.g., using private pasteboard types or transient data).
  - [ ] Explore if `Endpoint Security` framework or `Accessibility` APIs can be used to monitor other apps' clipboard interactions.
  - [ ] Document the feasibility of "Clipboard Defense" (detecting external reads).

## Dev Notes

- **Browser Detection:** Relying on Bundle IDs is stable. Detecting the *URL* or *Window Title* would require Screen Recording permissions or AX APIs, which might be overkill for the initial Guardian Mode. The goal for 2.4/2.5 is just identifying the *context* (Browser vs. IDE).
- **Clipboard Security:** Since `NSPasteboard` is a system-wide service, preventing all sniffing is impossible without system-level hooks. Research should focus on "Transient" markers (e.g., `org.nspasteboard.TransientType`) which some clipboard managers honor to skip recording.
- **Reference Architecture:** Follow the "Event-Based Actions" and "Actor State Integrity" from `project-context.md`.

### Project Structure Notes

- Prototype code should be kept in a separate `Spikes/` directory or discarded after documentation.
- Findings must be recorded in `docs/research/epic-2-spikes.md`.

### References

- [Source: _bmad-output/epics.md#Story 2.0]
- [Source: _bmad-output/project-context.md#Critical Implementation Rules]
- [Apple Documentation: NSWorkspace.frontmostApplication](https://developer.apple.com/documentation/appkit/nsworkspace/1532095-frontmostapplication)
- [Apple Documentation: NSPasteboard.PasteboardType.transient](https://developer.apple.com/documentation/appkit/nspasteboard/pasteboardtype/2881223-transient)

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Thinking)

### Debug Log References

### Completion Notes List

### File List
- _bmad-output/sprint-artifacts/2-0-technical-spikes.md
