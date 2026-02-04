# Source Tree Analysis: CodeMask

## Project Structure Overview

The project is organized using a **Feature-First** architecture, separating core system services from specific business features.

### Directory Tree

```text
CodeMask/
├── CodeMask/
│   ├── App/                # Application entry point, AppStore, and Environment
│   │   ├── CodeMaskApp.swift
│   │   ├── AppStore.swift
│   │   └── AppEnvironment.swift
│   ├── Core/               # Shared system-level services and infrastructure
│   │   ├── Security/       # Permissions and secure memory handling (mlock)
│   │   ├── Services/       # OS-level wrappers (Pasteboard, Keyboard, Audio, Haptic)
│   │   ├── Extensions/     # Foundation and AppKit extensions
│   │   └── Utilities/      # Logging and common helpers
│   ├── Features/           # Encapsulated business domains
│   │   ├── Clipboard/      # Regex-based masking engine and rule management
│   │   ├── Session/        # Secure in-memory token storage (SessionActor)
│   │   ├── Hotkeys/        # Carbon-based global hotkey orchestration
│   │   ├── HUD/            # AppKit NSPanel-based visual feedback overlays
│   │   └── UI/             # Menu Bar, Settings, and shared components
│   └── Resources/          # Asset catalogs and local presets
├── CodeMaskTests/          # Unit tests mirrored by feature
└── CodeMaskUITests/        # UI/XCUITest suite
```

### Critical Directories Explained

| Directory | Purpose | Key Files |
| :--- | :--- | :--- |
| `App/` | Central orchestration and state management | `AppStore.swift` |
| `Core/Security/` | Zero disk residue enforcement via memory locking | `SecureBuffer.swift` |
| `Features/Clipboard/` | Main logic loop for identifying and masking secrets | `RegexEngine.swift` |
| `Features/Session/` | Thread-safe, actor-isolated storage for tokens | `SessionActor.swift` |
| `Features/HUD/` | High-priority overlay management for user feedback | `HUDManager.swift` |

### Entry Points
- **App Entry**: `CodeMask/CodeMask/App/CodeMaskApp.swift`
- **Global Shortcut**: `CodeMask/CodeMask/Features/Hotkeys/GlobalHotkeyManager.swift`
- **Logic Trigger**: `AppStore.send(.clipboard(.startMasking))`
