import XCTest
@testable import NightSkyThomasCore

final class SkyEventTypeTests: XCTestCase {
    func testAllEventTypesHaveSymbols() {
        for type in SkyEventType.allCases {
            XCTAssertFalse(type.symbolName.isEmpty)
        }
    }
}
