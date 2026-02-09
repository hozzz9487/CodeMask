# Development Guide: CodeMask

## Prerequisites

- **Xcode 15.0+**
- **macOS 14.5+** (Sonoma)
- **Swift 5.9+**

## Project Setup

1. Open `CodeMask/CodeMask.xcodeproj` in Xcode.
2. Select the `CodeMask` scheme.
3. Ensure you have a valid Development Team set in Signing & Capabilities if testing on a local machine.

## Build & Run

- **Build**: `Cmd + B`
- **Run**: `Cmd + R`
- **Target**: My Mac (Native Apple Silicon or Intel)

## Testing

The project uses **XCTest** for unit and integration testing.

- **Run Unit Tests**: `Cmd + U`
- **Test Locations**:
  - `CodeMaskTests/Features/` (Feature logic)
  - `CodeMaskTests/Mocks/` (Dependency mocks)

### Key Test Commands (CLI)
```bash
# Run all tests
xcodebuild test -project CodeMask/CodeMask.xcodeproj -scheme CodeMask -destination 'platform=macOS'
```

## Security Best Practices

### Memory Locking
Sensitive data is handled via `SecureBuffer`. When developing features that touch raw strings:
- Use `SessionActor` for storage.
- Avoid logging raw clipboard content to `OSLog` or `print()`.

### Global Hotkeys
The app uses Carbon Events for global hotkeys. 
- **Default Masking**: `Cmd + Ctrl + C`
- **Default Restoration**: `Cmd + Ctrl + V`
