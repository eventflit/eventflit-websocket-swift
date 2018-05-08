import EventflitSwift
import XCTest

let VERSION = "6.0.0"

class ClientInitializationTests: XCTestCase {
    var key: String!
    var eventflit: Eventflit!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        eventflit = Eventflit(key: key)
    }

    func testCreatingTheConnection() {
        XCTAssertNotNil(eventflit.connection, "the connection should not be nil")
    }

    func testDefaultConnectionURLConfig() {
        XCTAssertEqual(eventflit.connection.url, "wss://service.eventflit.com:443/app/testKey123?client=eventflit-websocket-swift&version=\(VERSION)&protocol=7", "the connection URL should be set correctly")
    }

    func testDefaultAuthMethodConfig() {
        XCTAssertEqual(eventflit.connection.options.authMethod, AuthMethod.noMethod, "the default authMethod should be .noMethod")
    }

    func testDefaultAttemptToReturnJSONObjectConfig() {
        XCTAssertTrue(eventflit.connection.options.attemptToReturnJSONObject, "the default value for attemptToReturnJSONObject should be true")
    }

    func testDefaultHostConfig() {
        XCTAssertEqual(eventflit.connection.options.host, "service.eventflit.com", "the host should be set as \"service.eventflit.com\"")
    }

    func testDefaultPortConfig() {
        XCTAssertEqual(eventflit.connection.options.port, 443, "the port should be set as 443")
    }

    func testDefaultActivityTimeoutOption() {
        XCTAssertEqual(eventflit.connection.activityTimeoutInterval, 60, "the activity timeout interval should be 60")
    }

    func testProvidingEcryptedOptionAsFalse() {
        let options = EventflitClientOptions(
            encrypted: false
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.url, "ws://service.eventflit.com:80/app/testKey123?client=eventflit-websocket-swift&version=\(VERSION)&protocol=7", "the connection should be set correctly")
    }

    func testProvidingAnAuthEndpointAuthMethodOption() {
        let options = EventflitClientOptions(
            authMethod: .endpoint(authEndpoint: "http://myapp.com/auth-endpoint")
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.options.authMethod, AuthMethod.endpoint(authEndpoint: "http://myapp.com/auth-endpoint"), "the authMethod should be set correctly")
    }

    func testProvidingAnInlineAuthMethodOption() {
        let options = EventflitClientOptions(
            authMethod: .inline(secret: "superSecret")
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.options.authMethod, AuthMethod.inline(secret: "superSecret"), "the authMethod should be set correctly")
    }

    func testProvidingAttemptToReturnJSONObjectOptionAsFalse() {
        let options = EventflitClientOptions(
            attemptToReturnJSONObject: false
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertFalse(eventflit.connection.options.attemptToReturnJSONObject, "the attemptToReturnJSONObject option should be false")
    }

    func testProvidingAHostOption() {
        let options = EventflitClientOptions(
            host: EventflitHost.host("test.test.test")
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.options.host, "test.test.test", "the host should be \"test.test.test\"")
    }

    func testProvidingAPortOption() {
        let options = EventflitClientOptions(
            port: 123
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.options.port, 123, "the port should be 123")
    }

    func testProvidingAClusterOption() {
        let options = EventflitClientOptions(
            host: EventflitHost.cluster("eu")
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.options.host, "ws-eu.eventflit.com", "the host should be \"ws-eu.eventflit.com\"")
    }

    func testProvidingAnActivityTimeoutOption() {
        let options = EventflitClientOptions(
            activityTimeout: 123
        )
        eventflit = Eventflit(key: key, options: options)
        XCTAssertEqual(eventflit.connection.activityTimeoutInterval, 123, "the activity timeout interval should be 123")
    }
}
