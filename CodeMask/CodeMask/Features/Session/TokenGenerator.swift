import Foundation

// MARK: - Token Generator

/// A simple utility to generate unique tokens for session data.
/// Using a dedicated generator allows for future extensibility or mocking if needed.
struct TokenGenerator {
    
    /// Generates a unique UUID token.
    /// - Returns: A new UUID.
    func generate() -> UUID {
        return UUID()
    }
}
