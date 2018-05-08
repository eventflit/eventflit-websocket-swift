import EventflitSwift
import XCTest

class EventflitTopLevelApiTests: XCTestCase {
    class DummyDelegate: EventflitDelegate {
        var ex: XCTestExpectation? = nil
        var testingChannelName: String? = nil

        func subscribedToChannel(name: String) {
            if let cName = testingChannelName, cName == name {
                ex!.fulfill()
            }
        }
    }

    var key: String!
    var eventflit: Eventflit!
    var socket: MockWebSocket!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        let options = EventflitClientOptions(
            authMethod: AuthMethod.inline(secret: "secret"),
            autoReconnect: false
        )

        eventflit = Eventflit(key: key, options: options)
        socket = MockWebSocket()
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
    }

    func testCallingConnectCallsConnectOnTheSocket() {
        eventflit.connect()
        XCTAssertEqual(socket.stubber.calls[0].name, "connect")
    }

    func testConnectedPropertyIsTrueWhenConnectionConnects() {
        eventflit.connect()
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.connected)
    }

    func testCallingDisconnectCallsDisconnectOnTheSocket() {
        eventflit.connect()
        eventflit.disconnect()
        XCTAssertEqual(socket.stubber.calls[1].name, "disconnect")
    }

    func testConnectedPropertyIsFalseWhenConnectionDisconnects() {
        eventflit.connect()
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.connected)
        eventflit.disconnect()
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.disconnected)
    }

    func testCallingDisconnectSetsTheSubscribedPropertyOfChannelsToFalse() {
        eventflit.connect()
        let chan = eventflit.subscribe("test-channel")
        XCTAssertTrue(chan.subscribed)
        eventflit.disconnect()
        XCTAssertFalse(chan.subscribed)
    }

    /* subscribing to channels when already connected */

    /* public channels */

    func testChannelIsSetupCorrectly() {
        eventflit.connect()
        let chan = eventflit.subscribe("test-channel")
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testCallingSubscribeAfterSuccessfulConnectionSendsSubscribeEventOverSocket() {
        eventflit.connect()
        let _ = eventflit.subscribe("test-channel")

        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "the write function should have been called")
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["channel": "test-channel"], "event": "eventflit:subscribe"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }

    func testSubscribingToAPublicChannel() {
        eventflit.connect()
        let _ = eventflit.subscribe("test-channel")
        let testChannel = eventflit.connection.channels.channels["test-channel"]
        XCTAssertTrue(testChannel!.subscribed)
    }

    func testSubscriptionSucceededEventSentToGlobalChannel() {
        eventflit.connect()
        let callback = { (data: Any?) -> Void in
            if let data = data as? [String: Any], let eName = data["event"] as? String, eName == "eventflit:subscription_succeeded" {
                self.socket.appendToCallbackCheckString("globalCallbackCalled")
            }
        }
        let _ = eventflit.bind(callback)
        XCTAssertEqual(socket.callbackCheckString, "")
        let _ = eventflit.subscribe("test-channel")
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalled")
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectly() {
        eventflit.connect()
        let chan = eventflit.subscribe("private-channel")
        XCTAssertEqual(chan.name, "private-channel", "the channel name should be private-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        eventflit.delegate = dummyDelegate

        eventflit.connect()
        let _ = eventflit.subscribe(channelName)

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        eventflit.delegate = dummyDelegate

        eventflit.connect()
        let _ = eventflit.subscribe(channelName)

        waitForExpectations(timeout: 0.5)
    }

    /* subscribing to channels when starting disconnected */

    func testChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = eventflit.subscribe("test-channel")
        eventflit.connect()
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPublicChannelWhenCurrentlyDisconnected() {
        let _ = eventflit.subscribe("test-channel")
        let testChannel = eventflit.connection.channels.channels["test-channel"]
        eventflit.connect()
        XCTAssertTrue(testChannel!.subscribed)
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = eventflit.subscribe("private-channel")
        eventflit.connect()
        XCTAssertEqual(chan.name, "private-channel", "the channel name should be private-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        eventflit.connection.delegate = dummyDelegate

        let _ = eventflit.subscribe(channelName)
        eventflit.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        eventflit.connection.delegate = dummyDelegate

        let _ = eventflit.subscribe(channelName)
        eventflit.connect()

        waitForExpectations(timeout: 0.5)
    }

    /* unsubscribing */

    func testUnsubscribingFromAChannelRemovesTheChannel() {
        eventflit.connect()
        let _ = eventflit.subscribe("test-channel")

        XCTAssertNotNil(eventflit.connection.channels.channels["test-channel"], "test-channel should exist")
        eventflit.unsubscribe("test-channel")
        XCTAssertNil(eventflit.connection.channels.channels["test-channel"], "test-channel should not exist")
    }

    func testUnsubscribingFromAChannelSendsUnsubscribeEventOverSocket() {
        eventflit.connect()
        let _ = eventflit.subscribe("test-channel")
        eventflit.unsubscribe("test-channel")

        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "write function should have been called")

        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["channel": "test-channel"], "event": "eventflit:unsubscribe"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])

        XCTAssertTrue(parsedEqualsExpected)
    }

    func testUnsubscribingFromAllChannelsRemovesTheChannels() {
        eventflit.connect()
        let _ = eventflit.subscribe("test-channel")
        let _ = eventflit.subscribe("test-channel2")
        XCTAssertEqual(eventflit.connection.channels.channels.count, 2, "should have 2 channels")
        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "write function should have been called")
        eventflit.unsubscribeAll()

        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "write function should have been called")

        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["channel": "test-channel2"], "event": "eventflit:unsubscribe"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])

        XCTAssertTrue(parsedEqualsExpected)
        XCTAssertEqual(eventflit.connection.channels.channels.count, 0, "should have no channels")
    }

    /* global channel interactions */

    func testBindingToEventsGloballyAddsACallbackToTheGlobalChannel() {
        eventflit.connect()
        let callback = { (data: Any?) in }

        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
        let _ = eventflit.bind(callback)
        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
    }

    func testUnbindingAGlobalCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        eventflit.connect()
        let callback = { (data: Any?) in }
        let callBackId = eventflit.bind(callback)

        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
        eventflit.unbind(callbackId: callBackId)
        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAllGlobalCallbacksShouldRemoveAllCallbacksFromGlobalChannel() {
        eventflit.connect()
        let callback = { (data: Any?) in }
        let _ = eventflit.bind(callback)
        let callbackTwo = { (someData: Any?) in }
        let _ = eventflit.bind(callbackTwo)

        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 2, "the global channel should have 2 bound callbacks")
        eventflit.unbindAll()
        XCTAssertEqual(eventflit.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }
}
