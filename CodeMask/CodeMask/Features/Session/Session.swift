import Foundation

// MARK: - Session Feature Namespace

/// Namespace for Session-related State and Actions.
enum Session {
    
    struct State: Equatable {
        var sessionID: UUID?
    }
    
    enum Action: Equatable {
        case didSecureData(token: UUID)
        case didRetrieveData(content: String?)
        case didFail(AppError)
    }
}
