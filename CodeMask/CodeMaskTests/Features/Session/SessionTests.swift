import XCTest
@testable import CodeMask

final class SessionTests: XCTestCase {
    
    func testStateInitialization() {
        // Verify State struct exists and initializes
        let state = Session.State()
        XCTAssertNil(state.sessionID)
    }
    
    func testActions() {
        // Verify Action cases exist
        let uuid = UUID()
        let secureAction = Session.Action.didSecureData(token: uuid)
        let retrieveAction = Session.Action.didRetrieveData(content: "test")
        let failAction = Session.Action.didFail(AppError.unknown)
        
        // Pattern match to verify structure
        if case .didSecureData(let token) = secureAction {
            XCTAssertEqual(token, uuid)
        } else {
            XCTFail("Wrong action case for didSecureData")
        }
        
        if case .didRetrieveData(let content) = retrieveAction {
            XCTAssertEqual(content, "test")
        } else {
            XCTFail("Wrong action case for didRetrieveData")
        }
    }
}
