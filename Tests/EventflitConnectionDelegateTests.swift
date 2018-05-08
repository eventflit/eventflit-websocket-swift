import EventflitSwift
import XCTest

class EventflitConnectionDelegateTests: XCTestCase {
    open class DummyDelegate: EventflitDelegate {
        open let stubber = StubberForMocks()
        open var socket: MockWebSocket? = nil
        open var ex: XCTestExpectation? = nil
        var testingChannelName: String? = nil

        open func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
            let _ = stubber.stub(
                functionName: "connectionChange",
                args: [old, new],
                functionToCall: nil
            )
        }

        open func debugLog(message: String) {
            if message.range(of: "websocketDidReceiveMessage") != nil {
                self.socket?.appendToCallbackCheckString(message)
            }
        }

        open func subscribedToChannel(name: String) {
            if let cName = testingChannelName, cName == name {
                ex!.fulfill()
            }
        }

        open func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
            if let cName = testingChannelName, cName == name {
                ex!.fulfill()
            }
        }
    }

    var key: String!
    var eventflit: Eventflit!
    var socket: MockWebSocket!
    var dummyDelegate: DummyDelegate!

    override func setUp() {
        super.setUp()

        eventflit = Eventflit(key: "key", options: EventflitClientOptions(authMethod: .inline(secret: "superSecretSecret"), autoReconnect: false))
        socket = MockWebSocket()
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        dummyDelegate = DummyDelegate()
        dummyDelegate.socket = socket
        eventflit.delegate = dummyDelegate
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledTwiceGoingFromDisconnectedToConnectingToConnected() {
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.disconnected)
        eventflit.connect()
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.connected)
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledFourTimesGoingFromDisconnectedToConnectingToConnectedToDisconnectingToDisconnected() {
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.disconnected)
        eventflit.connect()
        XCTAssertEqual(eventflit.connection.connectionState, ConnectionState.connected)
        eventflit.disconnect()
        XCTAssertEqual(dummyDelegate.stubber.calls.count, 4)
        XCTAssertEqual(dummyDelegate.stubber.calls[2].name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls[2].args?.first as? ConnectionState, ConnectionState.connected)
        XCTAssertEqual(dummyDelegate.stubber.calls[2].args?.last as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.disconnected)
    }

    func testPassingIncomingMessagesToTheDebugLogFunctionIfOneIsImplemented() {
        eventflit.connect()

        XCTAssertEqual(socket.callbackCheckString, "[EVENTFLIT DEBUG] websocketDidReceiveMessage {\"event\":\"eventflit:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}")
    }

    func testsubscriptionDidSucceedDelegateFunctionGetsCalledWhenChannelSubscriptionSucceeds() {
        let ex = expectation(description: "the subscriptionDidSucceed function should be called")
        let channelName = "private-channel"
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName

        let _ = eventflit.subscribe(channelName)
        eventflit.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testsubscriptionDidFailDelegateFunctionGetsCalledWhenChannelSubscriptionFails() {
        let ex = expectation(description: "the subscriptionDidFail function should be called")
        let channelName = "private-channel"
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        eventflit.connection.options.authMethod = .noMethod

        let _ = eventflit.subscribe(channelName)
        eventflit.connect()

        waitForExpectations(timeout: 0.5)
    }
}
