import EventflitSwift
import XCTest

class HandlingIncomingEventsTests: XCTestCase {
    var key: String!
    var eventflit: Eventflit!
    var socket: MockWebSocket!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        eventflit = Eventflit(key: key)
        socket = MockWebSocket()
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
    }

    func testCallbacksOnGlobalChannelShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("testingIWasCalled") }
        let _ = eventflit.bind(callback)

        XCTAssertEqual(socket.callbackCheckString, "")
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "testingIWasCalled")
    }

    func testCallbacksOnRelevantChannelsShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let chan = eventflit.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertEqual(socket.callbackCheckString, "")
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "channelCallbackCalled")
    }

    func testCallbacksOnRelevantChannelsAndGlobalChannelShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("globalCallbackCalled") }
        let _ = eventflit.bind(callback)
        let chan = eventflit.subscribe("my-channel")
        let callbackForChannel = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let _ = chan.bind(eventName: "test-event", callback: callbackForChannel)

        XCTAssertEqual(socket.callbackCheckString, "")
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalledchannelCallbackCalled")
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = eventflit.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "{\"test\":\"test string\",\"and\":\"another\"}" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as! [String: String], ["test": "test string", "and": "another"])
    }

    func testReturningAJSONStringToCallbacksIfTheStringCannotBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = eventflit.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "test" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as? String, "test")
    }

    func testReturningAJSONStringToCallbacksIfTheStringCanBeParsedButAttemptToReturnJSONObjectIsFalse() {
        let options = EventflitClientOptions(attemptToReturnJSONObject: false)
        eventflit = Eventflit(key: key, options: options)
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = eventflit.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "{\"test\":\"test string\",\"and\":\"another\"}" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as? String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testReceivingAnErrorWhereTheDataPartOfTheMessageIsNotDoubleEncoded() {
        let _ = eventflit.bind({ (message: Any?) in
            if let message = message as? [String: AnyObject], let eventName = message["event"] as? String, eventName == "eventflit:error" {
                if let data = message["data"] as? [String: AnyObject], let errorMessage = data["message"] as? String {
                    self.socket.appendToCallbackCheckString(errorMessage)
                }
            }
        })

        // pretend that we tried to subscribe to my-channel twice and got this error
        // back from Eventflit
        eventflit.connection.handleEvent(eventName: "eventflit:error", jsonObject: ["event": "eventflit:error" as AnyObject, "data": ["code": "<null>", "message": "Existing subscription to channel my-channel"] as AnyObject])

        XCTAssertNil(socket.objectGivenToCallback)
        eventflit.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "test" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "Existing subscription to channel my-channel")
    }
}
