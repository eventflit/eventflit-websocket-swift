import Foundation
import StarscreamFork

let PROTOCOL = 7
let VERSION = "0.1.0"
let CLIENT_NAME = "eventflit-websocket-swift"

@objcMembers
@objc open class Eventflit: NSObject {
    open let connection: EventflitConnection
    open weak var delegate: EventflitDelegate? = nil {
        willSet {
            self.connection.delegate = newValue
#if os(iOS) || os(OSX)
            self.nativeEventflit.delegate = newValue
#endif
        }
    }
    private let key: String

#if os(iOS) || os(OSX)
    public let nativeEventflit: NativeEventflit

    /**
        Initializes the Eventflit client with an app key and any appropriate options.

        - parameter key:          The Eventflit app key
        - parameter options:      An optional collection of options
        - parameter nativeEventflit: A NativeEventflit instance for the app that the provided
                                  key belongs to

        - returns: A new Eventflit client instance
    */
    public init(key: String, options: EventflitClientOptions = EventflitClientOptions(), nativeEventflit: NativeEventflit? = nil) {
        self.key = key
        let urlString = constructUrl(key: key, options: options)
        let ws = WebSocket(url: URL(string: urlString)!)
        connection = EventflitConnection(key: key, socket: ws, url: urlString, options: options)
        connection.createGlobalChannel()
        self.nativeEventflit = nativeEventflit ?? NativeEventflit()
        self.nativeEventflit.setEventflitAppKey(eventflitAppKey: key)
    }
#endif

#if os(tvOS)
    /**
        Initializes the Eventflit client with an app key and any appropriate options.

        - parameter key:          The Eventflit app key
        - parameter options:      An optional collection of options

        - returns: A new Eventflit client instance
    */
    public init(key: String, options: EventflitClientOptions = EventflitClientOptions()) {
        self.key = key
        let urlString = constructUrl(key: key, options: options)
        let ws = WebSocket(url: URL(string: urlString)!)
        connection = EventflitConnection(key: key, socket: ws, url: urlString, options: options)
        connection.createGlobalChannel()
    }
#endif


    /**
        Subscribes the client to a new channel

        - parameter channelName:     The name of the channel to subscribe to
        - parameter auth:            A EventflitAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new EventflitChannel instance
    */
    open func subscribe(
        _ channelName: String,
        auth: EventflitAuth? = nil,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitChannel {
        return self.connection.subscribe(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )
    }

    /**
        Subscribes the client to a new presence channel. Use this instead of the subscribe
        function when you want a presence channel object to be returned instead of just a
        generic channel object (which you can then cast)

        - parameter channelName:     The name of the channel to subscribe to
        - parameter auth:            A EventflitAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new EventflitPresenceChannel instance
    */
    open func subscribeToPresenceChannel(
        channelName: String,
        auth: EventflitAuth? = nil,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitPresenceChannel {
        return self.connection.subscribeToPresenceChannel(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )
    }

    /**
        Unsubscribes the client from a given channel

        - parameter channelName: The name of the channel to unsubscribe from
    */
    open func unsubscribe(_ channelName: String) {
        self.connection.unsubscribe(channelName: channelName)
    }

    /**
        Unsubscribes the client from all channels
    */
    open func unsubscribeAll() {
        self.connection.unsubscribeAll()
    }

    /**
        Binds the client's global channel to all events

        - parameter callback: The function to call when a new event is received

        - returns: A unique string that can be used to unbind the callback from the client
    */
    @discardableResult open func bind(_ callback: @escaping (Any?) -> Void) -> String {
        return self.connection.addCallbackToGlobalChannel(callback)
    }

    /**
        Unbinds the client from its global channel

        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    open func unbind(callbackId: String) {
        self.connection.removeCallbackFromGlobalChannel(callbackId: callbackId)
    }

    /**
        Unbinds the client from all global callbacks
    */
    open func unbindAll() {
        self.connection.removeAllCallbacksFromGlobalChannel()
    }

    /**
        Disconnects the client's connection
    */
    open func disconnect() {
        self.connection.disconnect()
    }

    /**
        Initiates a connection attempt using the client's existing connection details
    */
    open func connect() {
        self.connection.connect()
    }
}

/**
    Creates a valid URL that can be used in a connection attempt

    - parameter key:     The app key to be inserted into the URL
    - parameter options: The collection of options needed to correctly construct the URL

    - returns: The constructed URL ready to use in a connection attempt
*/
func constructUrl(key: String, options: EventflitClientOptions) -> String {
    var url = ""

    if options.encrypted {
        url = "wss://\(options.host):\(options.port)/app/\(key)"
    } else {
        url = "ws://\(options.host):\(options.port)/app/\(key)"
    }
    return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
}
