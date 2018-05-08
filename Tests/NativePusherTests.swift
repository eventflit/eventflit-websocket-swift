#if os(iOS) || os(OSX)

@testable import EventflitSwift
import XCTest

func setUpDefaultMockResponses(eventflitClient: Eventflit, deviceClientId: String) {
    let jsonData = "{\"id\":\"\(deviceClientId)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)!
    let url = URL(string: "https://nativepushclient-cluster1.eventflit.com/client_api/v1/clients")!
    let urlResponse = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)
    MockSession.addMockResponse(for: url, httpMethod: "POST", data: jsonData, urlResponse: urlResponse, error: nil)

    let emptyJsonData = "".data(using: String.Encoding.utf8)!
    let subscriptionModificationUrl = URL(string: "https://nativepushclient-cluster1.eventflit.com/client_api/v1/clients/\(deviceClientId)/interests/donuts")!
    let susbcriptionModificationResponse = HTTPURLResponse(url: subscriptionModificationUrl, statusCode: 204, httpVersion: nil, headerFields: nil)
    let httpMethodForSubscribe = "POST"
    MockSession.addMockResponse(for: subscriptionModificationUrl, httpMethod: httpMethodForSubscribe, data: emptyJsonData, urlResponse: susbcriptionModificationResponse, error: nil)
    let httpMethodForUnsubscribe = "DELETE"
    MockSession.addMockResponse(for: subscriptionModificationUrl, httpMethod: httpMethodForUnsubscribe, data: emptyJsonData, urlResponse: susbcriptionModificationResponse, error: nil)

    eventflitClient.nativeEventflit.URLSession = MockSession.shared
}

class NativeEventflitTests: XCTestCase {
    public class DummyDelegate: EventflitDelegate {
        public var testClientId: String? = nil
        public var registerEx: XCTestExpectation? = nil
        public var subscribeEx: XCTestExpectation? = nil
        public var unsubscribeEx: XCTestExpectation? = nil
        public var registerFailEx: XCTestExpectation? = nil
        public var interestName: String? = nil

        public func subscribedToInterest(name: String) {
            if interestName == name {
                subscribeEx!.fulfill()
            }
        }

        public func unsubscribedFromInterest(name: String) {
            if interestName == name {
                unsubscribeEx!.fulfill()
            }
        }

        public func registeredForPushNotifications(clientId: String) {
            XCTAssertEqual(clientId, testClientId)
            registerEx!.fulfill()
        }

        public func failedToRegisterForPushNotifications(response: URLResponse, responseBody: String?) {
            registerFailEx!.fulfill()
        }
    }

    var key: String!
    var eventflit: Eventflit!
    var socket: MockWebSocket!
    var dummyDelegate: DummyDelegate!
    var testClientId: String!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        testClientId = "your_client_id"
        let options = EventflitClientOptions(
            authMethod: AuthMethod.inline(secret: "secret"),
            autoReconnect: false
        )

        eventflit = Eventflit(key: key, options: options)
        socket = MockWebSocket()
        socket.delegate = eventflit.connection
        eventflit.connection.socket = socket
        dummyDelegate = DummyDelegate()
        eventflit.delegate = dummyDelegate
    }

    func testReceivingAClientIdAfterRegisterIsCalled() {
        setUpDefaultMockResponses(eventflitClient: eventflit, deviceClientId: testClientId)

        let ex = expectation(description: "the clientId should be received when registration succeeds")
        dummyDelegate.testClientId = testClientId
        dummyDelegate.registerEx = ex

        eventflit.nativeEventflit.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)
        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAnInterest() {
        setUpDefaultMockResponses(eventflitClient: eventflit, deviceClientId: testClientId)

        let registerEx = expectation(description: "the clientId should be received when registration succeeds")
        let subscribeEx = expectation(description: "the client should successfully subscribe to an interest")

        dummyDelegate.testClientId = testClientId
        dummyDelegate.interestName = "donuts"
        dummyDelegate.registerEx = registerEx
        dummyDelegate.subscribeEx = subscribeEx

        eventflit.nativeEventflit.subscribe(interestName: "donuts")
        eventflit.nativeEventflit.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)

        waitForExpectations(timeout: 0.5)
    }

    func testUnsubscribingFromAnInterest() {
        setUpDefaultMockResponses(eventflitClient: eventflit, deviceClientId: testClientId)

        let registerEx = expectation(description: "the clientId should be received when registration succeeds")
        let subscribeEx = expectation(description: "the client should successfully subscribe to an interest")
        let unsubscribeEx = expectation(description: "the client should successfully unsubscribe from an interest")
        dummyDelegate.testClientId = testClientId
        dummyDelegate.interestName = "donuts"
        dummyDelegate.registerEx = registerEx
        dummyDelegate.subscribeEx = subscribeEx
        dummyDelegate.unsubscribeEx = unsubscribeEx

        eventflit.nativeEventflit.subscribe(interestName: "donuts")
        eventflit.nativeEventflit.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)
        eventflit.nativeEventflit.unsubscribe(interestName: "donuts")

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingWhenClientIdIsNotSetQueuesSubscriptionModificationRequest() {
        eventflit.nativeEventflit.clientId = nil

        XCTAssertEqual(eventflit.nativeEventflit.requestQueue.count, 0, "the nativeEventflit request queue should be empty")
        eventflit.nativeEventflit.subscribe(interestName: "donuts")

        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertEqual(eventflit.nativeEventflit.requestQueue.count, 1, "the nativeEventflit request queue should contain the subscribe request")
        XCTAssertEqual(eventflit.nativeEventflit.requestQueue.paused, true, "the nativeEventflit request queue should be paused")
    }

    func testFailingToRegisterWithEventflitForPushNotificationsCallsTheAppropriateDelegateFunction() {
        let jsonData = "".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let url = URL(string: "https://nativepushclient-cluster1.eventflit.com/client_api/v1/clients")!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
        MockSession.addMockResponse(for: url, httpMethod: "POST", data: jsonData, urlResponse: urlResponse, error: nil)
        eventflit.nativeEventflit.URLSession = MockSession.shared

        let registerFailEx = expectation(description: "the appropriate delegate should be called when registration fails")
        dummyDelegate.registerFailEx = registerFailEx

        eventflit.nativeEventflit.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)

        waitForExpectations(timeout: 0.5)
    }
}

#endif
