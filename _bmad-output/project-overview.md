# Project Overview: CodeMask

## Mission & Purpose
CodeMask is a native macOS utility designed to secure sensitive information (secrets, keys, PII) during development workflows. It identifies sensitive patterns in the clipboard using regex, replaces them with unique tokens, and stores the original data in secure, locked RAM for later restoration.

## Tech Stack Summary
- **Language**: Swift 5.0+ (Swift 6.2 Strict Concurrency enabled)
- **UI Framework**: SwiftUI (Main UI) + AppKit (NSPanel, NSStatusBar)
- **Architecture**: Unidirectional Flow (Central Store + Reducers)
- **Persistence**: Zero disk residue (RAM-only session storage)
- **Interactions**: Carbon Global Hotkeys & CGEvent Simulation

## Repository Structure
- **Type**: Monolith
- **Core Folder**: `CodeMask/CodeMask`
- **Output Artifacts**: `_bmad-output/`

## Key Documentation
- [Architecture Decision Document](./architecture.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)
- [Project Context (AI Rules)](./project-context.md)
- [UX Specification](./ux-design-specification.md)
- [Product Requirements](./prd.md)
