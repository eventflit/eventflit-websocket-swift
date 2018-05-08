import EventflitSwift
import XCTest

class EventflitPresenceChannelTests: XCTestCase {
    var eventflit: Eventflit!
    var socket: MockWebSocket!
    var options: EventflitClientOptions!
    var stubber: StubberForMocks!

    override func setUp() {
        super.setUp()

        options = EventflitClientOptions(
            authMethod: .inline(secret: "secret")
        )
        eventflit = Eventflit(key: "key", options: options)
        socket = MockWebSocket()
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        stubber = StubberForMocks()
    }

    func testMembersObjectStoresUserIdIfAUserDataFetcherIsProvided() {
        eventflit.connection.userDataFetcher = { () -> EventflitPresenceChannelMember in
            return EventflitPresenceChannelMember(userId: "123")
        }

        eventflit.connect()
        let chan = eventflit.subscribe("presence-channel") as? EventflitPresenceChannel
        XCTAssertEqual(chan?.members.first!.userId, "123", "the userId should be 123")
    }

    func testMembersObjectStoresSocketIdIfNoUserDataFetcherIsProvided() {
        eventflit.connect()
        let chan = eventflit.subscribe("presence-channel") as? EventflitPresenceChannel
        XCTAssertEqual(chan?.members.first!.userId, "46123.486095", "the userId should be 46123.486095")
    }

    func testMembersObjectStoresUserIdAndUserInfoIfAUserDataFetcherIsProvidedThatReturnsBoth() {
        eventflit = Eventflit(key: "testKey123", options: options)
        eventflit.connection.userDataFetcher = { () -> EventflitPresenceChannelMember in
            return EventflitPresenceChannelMember(userId: "123", userInfo: ["twitter": "hamchapman"] as Any?)
        }
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        eventflit.connect()
        let chan = eventflit.subscribe("presence-test") as? EventflitPresenceChannel

        XCTAssertEqual(chan?.members.first!.userId, "123", "the userId should be 123")
        XCTAssertEqual(chan?.members.first!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingEventflitPresenceChannelMemberByUserId() {
        eventflit.connect()

        let chan = eventflit.subscribe("presence-channel") as? EventflitPresenceChannel
        eventflit.connection.handleEvent(eventName: "eventflit_internal:member_added", jsonObject: ["event": "eventflit_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\", \"user_info\":{\"twitter\":\"hamchapman\"}}" as AnyObject])
        let member = chan!.findMember(userId: "100")

        XCTAssertEqual(member!.userId, "100", "the userId should be 100")
        XCTAssertEqual(member!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingTheClientsMemberObject() {
        eventflit.connection.userDataFetcher = { () -> EventflitPresenceChannelMember in
            return EventflitPresenceChannelMember(userId: "123", userInfo: ["friends": 0])
        }

        eventflit.connect()

        let chan = eventflit.subscribe("presence-channel") as? EventflitPresenceChannel
        let me = chan!.me()

        XCTAssertEqual(me!.userId, "123", "the userId should be 123")
        XCTAssertEqual(me!.userInfo as! [String: Int], ["friends": 0], "the userInfo should be [\"friends\": 0]")
    }

    func testFindingAPresenceChannelAsAEventflitPresenceChannel() {
        eventflit.connection.userDataFetcher = { () -> EventflitPresenceChannelMember in
            return EventflitPresenceChannelMember(userId: "123", userInfo: ["friends": 0])
        }

        eventflit.connect()

        let _ = eventflit.subscribe("presence-channel")

        let presChan = eventflit.connection.channels.findPresence(name: "presence-channel")

        XCTAssertNotNil(presChan, "the presence channel should be found and returned")
        XCTAssertEqual(presChan?.me()?.userId, "123", "the userId of the client's member object should be 123")
    }

    func testOnMemberAddedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = EventflitClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        eventflit = Eventflit(key: "key", options: options)
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        eventflit.connect()

        let memberAddedFunction = { (member: EventflitPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberAdded", args: [member], functionToCall: nil)
        }
        let _ = eventflit.subscribe("presence-channel", onMemberAdded: memberAddedFunction) as? EventflitPresenceChannel
        eventflit.connection.handleEvent(eventName: "eventflit_internal:member_added", jsonObject: ["event": "eventflit_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])

        XCTAssertEqual(stubber.calls.first?.name, "onMemberAdded", "the onMemberAdded function should have been called")
        XCTAssertEqual((stubber.calls.first?.args?.first as? EventflitPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = EventflitClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        eventflit = Eventflit(key: "key", options: options)
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        eventflit.connect()

        let memberRemovedFunction = { (member: EventflitPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberRemoved", args: [member], functionToCall: nil)
        }
        let chan = eventflit.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? EventflitPresenceChannel
        chan?.members.append(EventflitPresenceChannelMember(userId: "100"))

        eventflit.connection.handleEvent(eventName: "eventflit_internal:member_removed", jsonObject: ["event": "eventflit_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? EventflitPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceedsIfTheMemberUserIdWasNotAStringOriginally() {
        let options = EventflitClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        eventflit = Eventflit(key: "key", options: options)
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        eventflit.connect()
        let memberRemovedFunction = { (member: EventflitPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberRemoved", args: [member], functionToCall: nil)
        }
        let _ = eventflit.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? EventflitPresenceChannel
        eventflit.connection.handleEvent(eventName: "eventflit_internal:member_added", jsonObject: ["event": "eventflit_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])
        eventflit.connection.handleEvent(eventName: "eventflit_internal:member_removed", jsonObject: ["event": "eventflit_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? EventflitPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }
}
