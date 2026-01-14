import Foundation

// MARK: - Session Storage Protocol

/// Protocol defining session storage capabilities.
protocol SessionStorageProtocol: Actor {
    func store(content: String) -> UUID
    func retrieve(id: UUID) -> String?
    func clear()
}

// MARK: - Session Actor

/// Actor responsible for managing secure session storage.
/// Isolates access to `SecureBuffer` instances to ensure thread safety.
actor SessionActor: SessionStorageProtocol {
    
    // Internal storage mapping tokens to secure buffers
    private var storage: [UUID: SecureBuffer] = [:]
    
    private let tokenGenerator = TokenGenerator()
    
    /// Stores content securely in memory and returns a token.
    /// - Parameter content: The string to store.
    /// - Returns: A UUID token for retrieval.
    func store(content: String) -> UUID {
        // Create a unique token
        let id = tokenGenerator.generate()
        
        // Initialize secure buffer (locks memory immediately)
        let buffer = SecureBuffer(string: content)
        
        // Store in dictionary
        storage[id] = buffer
        
        return id
    }
    
    /// Retrieves content for a given token.
    /// - Parameter id: The UUID token.
    /// - Returns: The original string if found, otherwise nil.
    func retrieve(id: UUID) -> String? {
        // Check-After-Await is not strictly needed here as there are no suspension points,
        // but if we added async logic, we would need to verify state.
        
        guard let buffer = storage[id] else {
            return nil
        }
        
        // Retrieve transient string from buffer
        return buffer.retrieve()
    }
    
    /// explicitly clears all session data.
    /// SecureBuffer instances will be deallocated and their deinit will wipe memory.
    func clear() {
        storage.removeAll()
    }
}
