import XCTest
@testable import CodeMask

final class SessionActorTests: XCTestCase {
    
    func testStoreAndRetrieve() async {
        let actor = SessionActor()
        let secret = "my-secret-data"
        
        let token = await actor.store(content: secret)
        
        // Retrieve
        let retrieved = await actor.retrieve(id: token)
        XCTAssertEqual(retrieved, secret)
    }
    
    func testRetrieveInvalidToken() async {
        let actor = SessionActor()
        let invalidToken = UUID()
        
        let retrieved = await actor.retrieve(id: invalidToken)
        XCTAssertNil(retrieved)
    }
    
    func testDataIsolation() async {
        let actor = SessionActor()
        let secret1 = "secret-1"
        let secret2 = "secret-2"
        
        let token1 = await actor.store(content: secret1)
        let token2 = await actor.store(content: secret2)
        
        XCTAssertNotEqual(token1, token2)
        
        let retrieved1 = await actor.retrieve(id: token1)
        let retrieved2 = await actor.retrieve(id: token2)
        
        XCTAssertEqual(retrieved1, secret1)
        XCTAssertEqual(retrieved2, secret2)
    }
}
