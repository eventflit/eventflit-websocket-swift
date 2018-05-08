import EventflitSwift
import XCTest

class EventflitConnectionTests: XCTestCase {
    var key: String!
    var eventflit: Eventflit!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        eventflit = Eventflit(key: key)
    }

    func testUserDataFetcherIsNilByDefault() {
        XCTAssertNil(eventflit.connection.userDataFetcher, "userDataFetcher should be nil")
    }

    func testDelegateIsNilByDefault() {
        XCTAssertNil(eventflit.connection.delegate, "delegate should be nil")
    }

    func testSettingADelegate() {
        class DummyDelegate: EventflitDelegate {}
        let dummyDelegate = DummyDelegate()
        eventflit.delegate = dummyDelegate
        XCTAssertNotNil(eventflit.connection.delegate, "delegate should not be nil")
    }

    func testSettingAUserDataFetcher() {
        func fetchFunc() -> EventflitPresenceChannelMember {
            return EventflitPresenceChannelMember(userId: "1")
        }
        eventflit.connection.userDataFetcher = fetchFunc
        XCTAssertNotNil(eventflit.connection.userDataFetcher, "userDataFetcher should not be nil")
    }
}
