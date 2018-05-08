import EventflitSwift
import XCTest

class EventflitChannelTests: XCTestCase {
    var chan: EventflitChannel!

    override func setUp() {
        super.setUp()

        chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
    }

    func testANewChannelGetsCreatedWithTheCorrectNameAndNoCallbacks() {
        let chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }

    func testBindingACallbackToAChannelForAGivenEventName() {
        let chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 1, "the channel should have one callback")
    }

    func testUnbindingACallbackForAGivenEventNameAndCallbackId() {
        let chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
        XCTAssertNil(chan.eventHandlers["test-event"], "the channel should have no callbacks for event \"test-event\"")
        let idOne = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 2, "the channel should have two callbacks for event \"test-event\"")
        chan.unbind(eventName: "test-event", callbackId: idOne)
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 1, "the channel should have one callback for event \"test-event\"")
    }

    func testUnbindingAllCallbacksForAGivenEventName() {
        let chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
        XCTAssertNil(chan.eventHandlers["test-event"], "the channel should have no callbacks for event \"test-event\"")
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 2, "the channel should have two callbacks for event \"test-event\"")
        chan.unbindAll(forEventName: "test-event")
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 0, "the channel should have no callbacks for event \"test-event\"")
    }

    func testUnbindingAllCallbacksForAGivenChannel() {
        let chan = EventflitChannel(name: "test-channel", connection: MockEventflitConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        let _ = chan.bind(eventName: "test-event", callback: { (data: Any?) -> Void in })
        let _ = chan.bind(eventName: "test-event-3", callback: { (data: Any?) -> Void in })
        XCTAssertEqual(chan.eventHandlers.count, 2, "the channel should have two event names with callbacks")
        chan.unbindAll()
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }
}
