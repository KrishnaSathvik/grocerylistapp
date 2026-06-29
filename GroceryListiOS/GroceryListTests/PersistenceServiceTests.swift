import XCTest
@testable import GroceryList

final class PersistenceServiceTests: XCTestCase {
    func testSaveReturnsTrueWhenWriteSucceeds() {
        let result = PersistenceService.save(
            operation: "Test save",
            save: {},
            logger: { _ in XCTFail("Successful saves should not log failures") }
        )

        XCTAssertTrue(result)
    }

    func testSaveReturnsFalseAndLogsOperationWhenWriteFails() {
        var loggedMessage = ""

        let result = PersistenceService.save(
            operation: "Update item",
            save: { throw NSError(domain: "PersistenceServiceTests", code: 1) },
            logger: { loggedMessage = $0 }
        )

        XCTAssertFalse(result)
        XCTAssertTrue(loggedMessage.contains("Update item"))
        XCTAssertTrue(loggedMessage.contains("PersistenceServiceTests"))
    }
}
