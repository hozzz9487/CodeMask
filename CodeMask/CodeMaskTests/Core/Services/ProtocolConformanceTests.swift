
import XCTest
@testable import CodeMask

final class ProtocolConformanceTests: XCTestCase {
    
    func testPasteboardServiceProtocolConformance() {
        let service: PasteboardServiceProtocol = LivePasteboardService()
        XCTAssertNotNil(service)
    }
    
    func testHapticServiceProtocolConformance() {
        let service: HapticServiceProtocol = LiveHapticService()
        XCTAssertNotNil(service)
    }
    
    func testAudioServiceProtocolConformance() {
        let service: AudioServiceProtocol = LiveAudioService()
        XCTAssertNotNil(service)
    }
}
