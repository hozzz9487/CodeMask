
import Foundation
import CoreGraphics

protocol KeyboardServiceProtocol: Sendable {
    /// Simulates a Command + C keystroke to trigger a copy action in the active app.
    func simulateCopy() async
    
    /// Simulates a Command + V keystroke to trigger a paste action in the active app.
    func simulatePaste() async
}

final class LiveKeyboardService: KeyboardServiceProtocol {
    func simulateCopy() async {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Command down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        // C down
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand
        
        // C up
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        // Command up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        cDown?.post(tap: .cgAnnotatedSessionEventTap)
        cUp?.post(tap: .cgAnnotatedSessionEventTap)
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Small delay to allow the active application to process the copy event
        // and update the NSPasteboard.
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    }
    
    func simulatePaste() async {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Command down (0x37)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand // Force ONLY Command flag (strips Ctrl/Shift/etc)
        
        // V down (0x09)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        
        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        
        // Command up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.flags = [] // Clear flags
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        vDown?.post(tap: .cgAnnotatedSessionEventTap)
        vUp?.post(tap: .cgAnnotatedSessionEventTap)
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Small delay to allow paste to register
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
}
