
import AppKit

enum HapticFeedbackType: Sendable {
    case generic
    case alignment
    case levelChange
}

protocol HapticServiceProtocol: Sendable {
    func prepare()
    func play(_ feedback: HapticFeedbackType)
}

final class LiveHapticService: HapticServiceProtocol {
    
    // NSHapticFeedbackManager is thread-safe roughly, but mainly for UI thread.
    // Documentation says "The perform... method is thread safe".
    
    func prepare() {
        // No explicit preparation API for NSHapticFeedbackManager on macOS.
        // This is a no-op implementation to satisfy the protocol.
    }
    
    func play(_ feedback: HapticFeedbackType) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch feedback {
        case .generic:
            pattern = .generic
        case .alignment:
            pattern = .alignment
        case .levelChange:
            pattern = .levelChange
        }
        
        // Fire and forget, generally safe to call from any thread but perform implies UI interaction
        // Using MainActor.run might be safer if not on main, but doc says thread safe.
        // We will just call it.
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
