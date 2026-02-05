# Story 1.7: Mobile Presets & Advanced Regex

Status: done

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

- [x] **Model Updates** (Critical Pre-requisites)
  - [x] Update `Clipboard.Rule` struct in `Features/Clipboard/Models/Rule.swift`:
    - [x] Add `Codable` conformance.
    - [x] Add `name: String` property (e.g., "iOS Bundle ID") to support named presets.
    - [x] Update `init` and `defaults` to include the new `name` field.

- [x] **Data Resource Creation**
  - [x] Create directory `CodeMask/Resources/Presets/`.
  - [x] Create `MobilePack.json` containing the array of Rule objects.
  - [x] **Schema Requirements**: JSON must be an array of objects matching the updated `Rule` struct:
    ```json
    [ { "id": "UUID-STRING", "name": "Pattern Name", "pattern": "REGEX", "isEnabled": true } ]
    ```

- [x] **Logic Implementation**
  - [x] Create `PresetLoader.swift` in `Features/Clipboard/Services/` (or `Utilities/`) to load `MobilePack.json` from the Main Bundle.
  - [x] Update `RegexEngine` (or the app startup flow) to load these presets and merge them with default rules.
  - [x] **Constraint**: Do NOT create `ProfileManager` yet (Epic 3). Keep logic self-contained within `Features/Clipboard`.

- [x] **Testing & Validation**
  - [x] Unit Test: Verify `Clipboard.Rule` encodes/decodes correctly.
  - [x] Integration Test: Ensure `MobilePack.json` is successfully loaded and parsed.
  - [x] Performance: Verify loading presets does not violate the <100ms startup budget.

## Dev Notes

### Recommended Regex Patterns (Reference)
- **iOS Bundle ID**: `\bcom\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+\b`
- **Apple Team ID**: `\b[A-Z0-9]{10}\b` (e.g., `34A56789BC`)
- **Android Keystore Passwords**: `(?i)(storePassword|keyPassword)[\s:=]{1,10}\S+`
- **Google/Firebase API Key**: `AIza[0-9A-Za-z-_]{35}`

### Implementation Guide
- **Model Changes**: The current `Rule` struct is missing `Codable` and `name`. These are essential for file-based presets.
- **Directory**: `CodeMask/Resources/Presets/` is the correct location for data files.
- **Loading**: Use `JSONDecoder` with `Bundle.main.url(forResource:...)`.

### References

- [Source: _bmad-output/architecture.md#Project Structure & Boundaries] (Confirming `Resources/Presets/` location)
- [Source: _bmad-output/epics.md#Story 1.7: Mobile Presets & Advanced Regex]

## Dev Agent Record

### Agent Model Used

Gemini 2.0 Flash

### Debug Log References

- None

### Completion Notes List

- Implemented `Clipboard.Rule` updates (Codable, name).
- Created `MobilePack.json` with 4 mobile development regex patterns.
- Implemented `PresetLoader` to load patterns from Bundle.
- Integrated loader into `AppStore` initialization.
- Added comprehensive unit and integration tests.
- Refactored test path logic into reusable `TestUtils`.
- Improved error handling in `AppStore` for preset loading failures.

## File List

- CodeMask/CodeMask/Features/Clipboard/Models/Rule.swift
- CodeMask/CodeMaskTests/Features/Clipboard/Models/RuleTests.swift
- CodeMask/CodeMaskTests/Features/Clipboard/RegexEngineTests.swift
- CodeMask/CodeMask/Resources/Presets/MobilePack.json
- CodeMask/CodeMask/Features/Clipboard/Services/PresetLoader.swift
- CodeMask/CodeMaskTests/Features/Clipboard/Services/PresetLoaderTests.swift
- CodeMask/CodeMask/App/AppStore.swift
- CodeMask/CodeMaskTests/TestUtils.swift


## Change Log

- 2026-02-04: Implemented Story 1.7 (Mobile Presets). Added `MobilePack.json` and `PresetLoader`. Updated `Clipboard.Rule` to support names and Codable.

