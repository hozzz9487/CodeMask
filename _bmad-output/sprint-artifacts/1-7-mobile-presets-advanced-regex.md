# Story 1.7: Mobile Presets & Advanced Regex

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **mobile developer**,
I want **built-in support for iOS and Android secrets**,
so that **I am protected out of the box without complex configuration**.

## Acceptance Criteria

1. **Given** a new installation of CodeMask
2. **When** I use the default profile
3. **Then** it should include regex patterns for:
   - iOS Bundle IDs (e.g., `com.company.app`)
   - Apple Team IDs (e.g., `10-digit alphanumeric`)
   - Android Keystores (file paths or password patterns if detectable in clipboard text) and Signing Configs
4. **And** these patterns must be optimized for performance to ensure the <100ms latency requirement.

## Tasks / Subtasks

- [ ] **Data Resource Creation**
  - [ ] Create directory `CodeMask/Resources/Presets/` if it doesn't exist.
  - [ ] Create `MobilePack.json` defining the regex rules for iOS and Android secrets.
  - [ ] Ensure JSON structure validates against the `RuleSet` model (or implicit model used by RegexEngine).

- [ ] **Logic Implementation**
  - [ ] Implement/Update `PresetLoader` (or equivalent in `ProfileManager`/`RegexEngine`) to load `MobilePack.json` from the Main Bundle.
  - [ ] Ensure default profile initializes with these rules active.
  - [ ] Verify `CodeMask/Features/Profiles/` structure encompasses preset loading if `ProfileManager` is already present, otherwise handle in `RegexEngine`.

- [ ] **Testing & Validation**
  - [ ] Add unit tests in `CodeMaskTests` verifying identifying valid Bundle IDs, Team IDs, etc.
  - [ ] Add unit tests verifying *false positives* are minimized.
  - [ ] Performance benchmark: Ensure regex matching stays under 10 ms for typical clipboard payloads, contributing to the total <100ms budget.

## Dev Notes

- **Architecture Patterns**:
  - Use **Native Swift Regex** (Swift 5.7+).
  - Store presets in `Resources/Presets/` as per Architecture Spec.
  - Load via `Bundle.main.url(forResource:...)`.
  
- **Project Structure**:
  - `CodeMask/Resources/Presets/MobilePack.json`
  - `CodeMask/Features/Profiles/ProfileManager.swift` (likely place for loading logic if it exists, else `RegexEngine.swift`).

- **Testing Standards**:
  - Use `XCTest` with sample data.
  - No external dependencies.

### References

- [Source: _bmad-output/architecture.md#Project Structure & Boundaries] (Confirming `Resources/Presets/` location)
- [Source: _bmad-output/epics.md#Story 1.7: Mobile Presets & Advanced Regex]

## Dev Agent Record

### Agent Model Used

Gemini 2.0 Flash

### Debug Log References

- None

### Completion Notes List

- Created structure for Mobile Presets.
- Identified critical regex patterns needed.
