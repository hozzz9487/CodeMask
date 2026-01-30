
import Foundation

/// Namespace for Clipboard feature
enum Clipboard {
    struct State: Equatable {
        var lastMaskingResult: MatchResult?
        var isMasking: Bool = false
        
        static func == (lhs: State, rhs: State) -> Bool {
            // MatchResult equality check might be expensive or needed.
            // For now, identity based on structure? MatchResult is Sendable struct.
            // We'll skip complex equality for now or implement Equatable on MatchResult later.
            return lhs.isMasking == rhs.isMasking
        }
    }
    
    enum Action {
        case startMasking
        case maskingSequenceCompleted(Result<Bool, Error>) 
    }
}
