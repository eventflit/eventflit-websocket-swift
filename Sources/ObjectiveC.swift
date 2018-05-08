import Foundation

@objc public extension Eventflit {
    public func subscribe(channelName: String) -> EventflitChannel {
        return self.subscribe(channelName, onMemberAdded: nil, onMemberRemoved: nil)
    }

    public func subscribe(
        channelName: String,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitChannel {
        return self.subscribe(channelName, auth: nil, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    public func subscribeToPresenceChannel(channelName: String) -> EventflitPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName, auth: nil, onMemberAdded: nil, onMemberRemoved: nil)
    }

    public func subscribeToPresenceChannel(
        channelName: String,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName, auth: nil, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    public convenience init(withAppKey key: String, options: EventflitClientOptions) {
        self.init(key: key, options: options)
    }

    public convenience init(withKey key: String) {
        self.init(key: key)
    }
}

@objc public extension EventflitConnection {
    public var OCReconnectAttemptsMax: NSNumber? {
        get {
            return reconnectAttemptsMax as NSNumber?
        }
        set(newValue) {
            reconnectAttemptsMax = newValue?.intValue
        }
    }

    public var OCMaxReconnectGapInSeconds: NSNumber? {
        get {
            return maxReconnectGapInSeconds as NSNumber?
        }
        set(newValue) {
            maxReconnectGapInSeconds = newValue?.doubleValue
        }
    }
}

@objc public extension EventflitClientOptions {
    public convenience init(
        ocAuthMethod authMethod: OCAuthMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        ocHost host: OCEventflitHost = EventflitHost.host("service.eventflit.com").toObjc(),
        port: NSNumber? = nil,
        encrypted: Bool = true,
        activityTimeout: NSNumber? = nil
    ) {
        self.init(
            authMethod: AuthMethod.fromObjc(source: authMethod),
            attemptToReturnJSONObject: attemptToReturnJSONObject,
            autoReconnect: autoReconnect,
            host: EventflitHost.fromObjc(source: host),
            port: port as? Int,
            encrypted: encrypted,
            activityTimeout: activityTimeout as? TimeInterval
        )
    }

    public convenience init(authMethod: OCAuthMethod) {
        self.init(authMethod: AuthMethod.fromObjc(source: authMethod))
    }

    public func setAuthMethod(authMethod: OCAuthMethod) {
        self.authMethod = AuthMethod.fromObjc(source: authMethod)
    }
}


public extension EventflitHost {
    func toObjc() -> OCEventflitHost {
        switch self {
        case let .host(host):
            return OCEventflitHost(host: host)
        case let .cluster(cluster):
            return OCEventflitHost(cluster: "ws-\(cluster).eventflit.com")
        }
    }

    static func fromObjc(source: OCEventflitHost) -> EventflitHost {
        switch (source.type) {
        case 0: return EventflitHost.host(source.host!)
        case 1: return EventflitHost.cluster(source.cluster!)
        default: return EventflitHost.host("service.eventflit.com")
        }
    }
}

@objcMembers
@objc public class OCEventflitHost: NSObject {
    var type: Int
    var host: String? = nil
    var cluster: String? = nil

    public override init() {
        self.type = 2
    }

    public init(host: String) {
        self.type = 0
        self.host = host
    }

    public init(cluster: String) {
        self.type = 1
        self.cluster = cluster
    }
}

public extension AuthMethod {
    func toObjc() -> OCAuthMethod {
        switch self {
        case let .endpoint(authEndpoint):
            return OCAuthMethod(authEndpoint: authEndpoint)
        case let .authRequestBuilder(authRequestBuilder):
            return OCAuthMethod(authRequestBuilder: authRequestBuilder)
        case let .inline(secret):
            return OCAuthMethod(secret: secret)
        case let .authorizer(authorizer):
            return OCAuthMethod(authorizer: authorizer)
        case .noMethod:
            return OCAuthMethod(type: 4)
        }
    }

    static func fromObjc(source: OCAuthMethod) -> AuthMethod {
        switch (source.type) {
        case 0: return AuthMethod.endpoint(authEndpoint: source.authEndpoint!)
        case 1: return AuthMethod.authRequestBuilder(authRequestBuilder: source.authRequestBuilder!)
        case 2: return AuthMethod.inline(secret: source.secret!)
        case 3: return AuthMethod.authorizer(authorizer: source.authorizer!)
        case 4: return AuthMethod.noMethod
        default: return AuthMethod.noMethod
        }
    }
}

@objcMembers
@objc public class OCAuthMethod: NSObject {
    var type: Int
    var secret: String? = nil
    var authEndpoint: String? = nil
    var authRequestBuilder: AuthRequestBuilderProtocol? = nil
    var authorizer: Authorizer? = nil

    public init(type: Int) {
        self.type = type
    }

    public init(authEndpoint: String) {
        self.type = 0
        self.authEndpoint = authEndpoint
    }

    public init(authRequestBuilder: AuthRequestBuilderProtocol) {
        self.type = 1
        self.authRequestBuilder = authRequestBuilder
    }

    public init(secret: String) {
        self.type = 2
        self.secret = secret
    }

    public init(authorizer: Authorizer) {
        self.type = 3
        self.authorizer = authorizer
    }
}
