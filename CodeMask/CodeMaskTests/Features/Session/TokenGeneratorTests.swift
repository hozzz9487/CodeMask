import XCTest
@testable import CodeMask

final class TokenGeneratorTests: XCTestCase {
    
    func testTokenGeneration() {
        let generator = TokenGenerator()
        let token1 = generator.generate()
        let token2 = generator.generate()
        
        XCTAssertNotEqual(token1, token2)
    }
}
