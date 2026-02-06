import Foundation

// MARK: - Session Feature Namespace

/// Namespace for Session-related State and Actions.
enum Session {
    
    enum SecurityStatus: Equatable {
        case idle
        case secured
        case warning
        case unknown
    }

    struct State: Equatable {
        var sessionID: UUID?
        var hasSecrets: Bool = false
        var isDanger: Bool = false
        var isStatusKnown: Bool = true
        
        var securityStatus: SecurityStatus {
            if !isStatusKnown {
                return .unknown
            }
            
            if isDanger {
                return .warning
            }
            
            if hasSecrets {
                return .secured
            }
            
            return .idle
        }
    }
    
    enum Action: Equatable {
        case didSecureData(token: UUID)
        case didRetrieveData(content: String?)
        case didUpdateDanger(isDanger: Bool)
        case didFail(AppError)
    }
}
