
import AppKit
import SwiftUI
import Combine

@MainActor
final class HUDManager {
    private var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()
    private let store: AppStore
    
    init(store: AppStore) {
        self.store = store
        setupObservation()
    }
    
    private func setupObservation() {
        // Observe isVisible state change using SwiftUI Observation mechanism bridge
        // or simple poll/Combine if needed. Since AppStore is @Observable, we can use 
        // withObservationTracking if we were in a view, but in a manager we might need 
        // a different approach or just use the Combine bridge we built.
        
        // For simplicity and reliability in this AppKit bridge, we'll observe the store's 
        // properties. Note: @Observable doesn't provide easy Combine publishers out of box 
        // without extra work. Let's use the fact that HUD state changes trigger updates.
        
        // Better: Use Task to observe changes if using Swift 6, or just bridge it.
        Task {
            var lastState: HUD.State? = nil
            
            while true {
                let currentState = store.hud
                
                if currentState != lastState {
                    if currentState.isVisible {
                        showHUD(message: currentState.message, type: currentState.type)
                    } else {
                        hideHUD()
                    }
                    lastState = currentState
                }
                
                // 100ms poll is fine for responsiveness, but now it's "silent" if no change
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    private func showHUD(message: String, type: HUD.State.FeedbackType) {
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        // Update content
        let hostingView = NSHostingView(rootView: HUDView(message: message, type: type))
        window.contentView = hostingView
        
        // Dynamic Resizing: Adjust window size to fit content
        let fittingSize = hostingView.fittingSize
        window.setContentSize(fittingSize)
        
        // Position in center of screen with active mouse
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.origin.x + (screenRect.width - fittingSize.width) / 2
            let y = screenRect.origin.y + (screenRect.height - fittingSize.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.orderFrontRegardless()
    }
    
    private func hideHUD() {
        window?.orderOut(nil)
        // Clear content to avoid VRAM residue as per architecture decision
        window?.contentView = nil
    }
    
    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .mainMenu + 1 // Ensure it's above almost everything
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true // Let user click through it
        
        self.window = panel
    }
}
