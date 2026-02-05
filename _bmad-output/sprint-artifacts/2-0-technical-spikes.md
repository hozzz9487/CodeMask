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

- [ ] Task 0: Spike Environment Setup (Critical Fix)
  - [ ] Create directory structure `docs/research/` if it doesn't exist (Project `docs` folder seems missing).
  - [ ] Add `Spikes/` to `.gitignore` to prevent temporary prototype code from polluting the repo.
  - [ ] Create temporary `Spikes/` directory for prototype code.

- [ ] Task 1: Browser Detection Spike (AC: 1)
  - [ ] Implement a prototype in `Spikes/BrowserDetection` using `NSWorkspaceDidActivateApplicationNotification`.
  - [ ] Measure latency between application switch and detection.
  - [ ] Test with major browsers (Safari, Chrome, Firefox, Arc) using bundle identifiers.
  - [ ] Verify if `NSPrivacyAccessedAPITypes` (specifically `NSPrivacyAccessedAPICategorySystemBootTime` or similar) is required for `NSWorkspace` usage.

- [ ] Task 2: Clipboard Security Research (AC: 2)
  - [ ] Implement a prototype in `Spikes/ClipboardSecurity` accessing `NSPasteboard`.
  - [ ] Investigate `NSPasteboard` APIs for any "access" callbacks or ownership tracking.
  - [ ] Research "Clipboard Stealth" techniques (e.g., `org.nspasteboard.TransientType`).
  - [ ] Document findings clearly in `docs/research/epic-2-spikes.md`.

## Definition of Done (Spike Specific)

- [ ] **Artifact:** A comprehensive research report is committed to `docs/research/epic-2-spikes.md`.
- [ ] **Conclusion:** Each research question must have a clear "YES/NO" or "Feasible/Not Feasible" conclusion.
- [ ] **Cleanup:** Temporary code in `Spikes/` is either deleted or explicitly ignored by git.
- [ ] **Next Steps:** Recommendations for Stories 2.3, 2.4, and 2.5 are documented in the report.

## Dev Notes

- **Browser Detection:** Relying on Bundle IDs is stable. Detecting the *URL* or *Window Title* would require Screen Recording permissions, which is overkill. The goal is identifying *context* (Browser vs. IDE).
- **Clipboard Security:** Focus on "Transient" markers (`org.nspasteboard.TransientType`) which some clipboard managers honor.
- **Reference Architecture:** Follow the "Event-Based Actions" and "Actor State Integrity" from `project-context.md`.

### Project Structure Notes

- Prototype code: `Spikes/` (Git ignored).
- Documentation: `docs/research/epic-2-spikes.md` (Committed).

### References

- [Source: _bmad-output/epics.md#Story 2.0]
- [Source: _bmad-output/project-context.md#Critical Implementation Rules]
- [Apple Documentation: NSWorkspace.frontmostApplication](https://developer.apple.com/documentation/appkit/nsworkspace/1532095-frontmostapplication)
- [Apple Documentation: Describing Use of Privacy-Sensitive Data](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)
- [Apple Documentation: NSPasteboard.PasteboardType.transient](https://developer.apple.com/documentation/appkit/nspasteboard/pasteboardtype/2881223-transient)

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Thinking)

### Debug Log References

### Completion Notes List

### File List
- _bmad-output/sprint-artifacts/2-0-technical-spikes.md
