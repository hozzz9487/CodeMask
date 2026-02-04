import Foundation

// MARK: - Session Storage Protocol

/// Protocol defining session storage capabilities.
protocol SessionStorageProtocol: Actor {
    func store(content: String) -> UUID
    func store(batch: [String: String])
    func retrieve(id: UUID) -> String?
    func resolve(tokens: [String]) -> [String: String?]
    func clear()
}

// MARK: - Session Actor

/// Actor responsible for managing secure session storage.
/// Isolates access to `SecureBuffer` instances to ensure thread safety.
actor SessionActor: SessionStorageProtocol {
    
    // Internal storage mapping tokens to secure buffers
    private var storage: [String: SecureBuffer] = [:]
    
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
        storage[id.uuidString] = buffer
        
        return id
    }
    
    /// Batch stores content with provided IDs (String keys).
    func store(batch: [String: String]) {
        for (id, content) in batch {
            storage[id] = SecureBuffer(string: content)
        }
    }
    
    /// Retrieves content for a given token.
    /// - Parameter id: The UUID token.
    /// - Returns: The original string if found, otherwise nil.
    func retrieve(id: UUID) -> String? {
        return retrieve(idString: id.uuidString)
    }
    
    /// Batch resolves tokens to their original secrets.
    /// - Parameter tokens: List of token IDs (short IDs).
    /// - Returns: Dictionary mapping token ID to secret (or nil if not found).
    func resolve(tokens: [String]) -> [String: String?] {
        var results: [String: String?] = [:]
        for token in tokens {
            if let buffer = storage[token] {
                results[token] = buffer.retrieve()
            } else {
                results[token] = nil
            }
        }
        return results
    }
    
    /// Retrieves content for a given string ID.
    func retrieve(idString: String) -> String? {
        guard let buffer = storage[idString] else {
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
