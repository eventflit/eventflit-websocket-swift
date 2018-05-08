# EventflitSwift eventflit-websocket-swift (and Objective-C)

![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
[![Platform](https://img.shields.io/cocoapods/p/EventflitSwift.svg?style=flat)](http://cocoadocs.org/docsets/EventflitSwift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/EventflitSwift.svg)](https://img.shields.io/cocoapods/v/EventflitSwift.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Eventflit-blue.svg?style=flat)](http://twitter.com/Eventflit)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/eventflit/eventflit-websocket-swift/master/LICENSE.md)

Supports iOS, macOS (OS X) and tvOS! (Hopefully watchOS soon!)


## I just want to copy and paste some code to get me started

What else would you want? Head over to one of our example apps:

* For iOS with Swift, see [ViewController.swift](https://github.com/eventflit/eventflit-websocket-swift/blob/master/iOS%20Example%20Swift/iOS%20Example%20Swift/ViewController.swift)
* For iOS with Objective-C, see [ViewController.m](https://github.com/eventflit/eventflit-websocket-swift/blob/master/iOS%20Example%20Obj-C/iOS%20Example%20Obj-C/ViewController.m)
* For macOS with Swift, see [AppDelegate.swift](https://github.com/eventflit/eventflit-websocket-swift/blob/master/macOS%20Example%20Swift/macOS%20Example%20Swift/AppDelegate.swift)


## Table of Contents

* [Installation](#installation)
* [Configuration](#configuration)
* [Connection](#connection)
  * [Connection delegate](#connection-delegate)
  * [Reconnection](#reconnection)
* [Subscribing to channels](#subscribing)
  * [Public channels](#public-channels)
  * [Private channels](#private-channels)
  * [Presence channels](#presence-channels)
* [Binding to events](#binding-to-events)
  * [Globally](#global-events)
  * [Per-channel](#per-channel-events)
  * [Receiving errors](#receiving-errors)
* [Push notifications](#push-notifications)
  * [Eventflit delegate](#eventflit-delegate)
* [Testing](#testing)
* [Extensions](#extensions)
* [Communication](#communication)
* [Credits](#credits)
* [License](#license)


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects and is our recommended method of installing EventflitSwift and its dependencies.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate EventflitSwift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

pod 'EventflitSwift', '~> 0.1'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update EventflitSwift
$ pod install
```

Also you'll need to make sure that you've not got the version of EventflitSwift locked to an old version in your `Podfile.lock` file.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate EventflitSwift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "eventflit/eventflit-websocket-swift"
```

## Configuration

There are a number of configuration parameters which can be set for the Eventflit client. For Swift usage they are:

- `authMethod (AuthMethod)` - the method you would like the client to use to authenticate subscription requests to channels requiring authentication (see below for more details)
- `attemptToReturnJSONObject (Bool)` - whether or not you'd like the library to try and parse your data as JSON (or not, and just return a string)
- `encrypted (Bool)` - whether or not you'd like to use encypted transport or not, default is `true`
- `autoReconnect (Bool)` - set whether or not you'd like the library to try and autoReconnect upon disconnection
- `host (EventflitHost)` - set a custom value for the host you'd like to connect to, e.g. `EventflitHost.host("ws-test.eventflit.com")`
- `port (Int)` - set a custom value for the port that you'd like to connect to
- `activityTimeout (TimeInterval)` - after this time (in seconds) without any messages received from the server, a ping message will be sent to check if the connection is still working; the default value is supplied by the server, low values will result in unnecessary traffic.

The `authMethod` parameter must be of the type `AuthMethod`. This is an enum defined as:

```swift
public enum AuthMethod {
    case endpoint(authEndpoint: String)
    case authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case inline(secret: String)
    case authorizer(authorizer: Authorizer)
    case noMethod
}
```

- `endpoint(authEndpoint: String)` - the client will make a `POST` request to the endpoint you specify with the socket ID of the client and the channel name attempting to be subscribed to
- `authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)` - you specify an object that conforms to the `AuthRequestBuilderProtocol` (defined below), which must generate an `URLRequest` object that will be used to make the auth request
- `inline(secret: String)` - your app's secret so that authentication requests do not need to be made to your authentication endpoint and instead subscriptions can be authenticated directly inside the library (this is mainly desgined to be used for development)
- `authorizer(authorizer: Authorizer)` - you specify an object that conforms to the `Authorizer` protocol which must be able to provide the appropriate auth information
- `noMethod` - if you are only using public channels then you do not need to set an `authMethod` (this is the default value)

This is the `AuthRequestBuilderProtocol` definition:

```swift
public protocol AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest?
}
```

This is the `Authorizer` protocol definition:

```swift
public protocol Authorizer {
    func fetchAuthValue(socketID: String, channelName: String, completionHandler: (EventflitAuth?) -> ())
}
```

where `EventflitAuth` is defined as:

```swift
public class EventflitAuth: NSObject {
    public let auth: String
    public let channelData: String?

    public init(auth: String, channelData: String? = nil) {
        self.auth = auth
        self.channelData = channelData
    }
}
```

Provided the authorization process succeeds you need to then call the supplied `completionHandler` with a `EventflitAuth` object so that the subscription process can complete.

If for whatever reason your authorization process fails then you just need to call the `completionHandler` with `nil` as the only parameter.

Note that if you want to specify the cluster to which you want to connect then you use the `host` property as follows:

#### Swift
```swift
let options = EventflitClientOptions(
    host: .cluster("eu")
)
```

#### Objective-C
```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/eventflit/auth"];
OCEventflitHost *host = [[OCEventflitHost alloc] initWithCluster:@"eu"];
EventflitClientOptions *options = [[EventflitClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                attemptToReturnJSONObject:YES
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                encrypted:YES];
```

All of these configuration options need to be passed to a `EventflitClientOptions` object, which in turn needs to be passed to the Eventflit object, when instantiating it, for example:

#### Swift
```swift
let options = EventflitClientOptions(
    authMethod: .endpoint(authEndpoint: "http://localhost:9292/eventflit/auth")
)

let eventflit = Eventflit(key: "APP_KEY", options: options)
```

#### Objective-C
```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/eventflit/auth"];
OCEventflitHost *host = [[OCEventflitHost alloc] initWithCluster:@"eu"];
EventflitClientOptions *options = [[EventflitClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                attemptToReturnJSONObject:YES
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                encrypted:YES];
eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY" options:options];
```

As you may have noticed, this differs slightly for Objective-C usage. The main changes are that you need to use `OCAuthMethod` and `OCEventflitHost` in place of `AuthMethod` and `EventflitHost`. The `OCAuthMethod` class has the following functions that you can call in your Objective-C code.

```swift
public init(authEndpoint: String)

public init(authRequestBuilder: AuthRequestBuilderProtocol)

public init(secret: String)

public init()
```

```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
EventflitClientOptions *options = [[EventflitClientOptions alloc] initWithAuthMethod:authMethod];
```

The case is similar for `OCEventflitHost`. You have the following functions available:

```objc
public init(host: String)

public init(cluster: String)
```

```objc
[[OCEventflitHost alloc] initWithCluster:@"YOUR_CLUSTER_SHORTCODE"];
```

Authenticated channel example:

#### Swift
```swift
class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/builder")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channel.name)".data(using: String.Encoding.utf8)
        request.addValue("myToken", forHTTPHeaderField: "Authorization")
        return request
    }
}

let options = EventflitClientOptions(
    authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
)
let eventflit = Eventflit(
  key: "APP_KEY",
  options: options
)
```

#### Objective-C
```objc
@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@implementation AuthRequestBuilder

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://localhost:9292/eventflit/auth"]];
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/eventflit/auth"]];

    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, channelName];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    mutableRequest.HTTPBody = data;
    mutableRequest.HTTPMethod = @"POST";
    [mutableRequest addValue:@"myToken" forHTTPHeaderField:@"Authorization"];

    request = [mutableRequest copy];

    return request;
}

@end

OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthRequestBuilder:[[AuthRequestBuilder alloc] init]];
EventflitClientOptions *options = [[EventflitClientOptions alloc] initWithAuthMethod:authMethod];
```

Where `"Authorization"` and `"myToken"` are the field and value your server is expecting in the headers of the request.

## Connection

A Websocket connection is established by providing your API key to the constructor function:

#### Swift
```swift
let eventflit = Eventflit(key: "APP_KEY")
eventflit.connect()
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
[eventflit connect];
```

This returns a client object which can then be used to subscribe to channels and then calling `connect()` triggers the connection process to start.

You can also set a `userDataFetcher` on the connection object.

- `userDataFetcher (() -> EventflitPresenceChannelMember)` - if you are subscribing to an authenticated channel and wish to provide a function to return user data

You set it like this:

#### Swift
```swift
let eventflit = Eventflit(key: "APP_KEY")

eventflit.connection.userDataFetcher = { () -> EventflitPresenceChannelMember in
    return EventflitPresenceChannelMember(userId: "123", userInfo: ["twitter": "hamchapman"])
}
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];

eventflit.connection.userDataFetcher = ^EventflitPresenceChannelMember* () {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [[EventflitPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
};
```

### Connection delegate

There is a `EventflitDelegate` that you can use to get notified of connection-related information. These are the functions that you can optionally implement when conforming to the `EventflitDelegate` protocol:

```swift
@objc optional func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
@objc optional func subscribedToChannel(name: String)
@objc optional func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)
@objc optional func debugLog(message: String)
```

The names of the functions largely give away what their purpose is but just for completeness:

- `changedConnectionState` - use this if you want to use connection state changes to perform different actions / UI updates
- `subscribedToChannel` - use this if you want to be informed of when a channel has successfully been subscribed to, which is useful if you want to perform actions that are only relevant after a subscription has succeeded, e.g. logging out the members of a presence channel
- `failedToSubscribeToChannel` - use this if you want to be informed of a failed subscription attempt, which you could use, for exampple, to then attempt another subscription or make a call to a service you use to track errors
- `debugLog` - use this if you want to log Eventflit-related events, e.g. the underlying websocket receiving a message

Setting up a delegate looks like this:

#### Swift
```swift
class ViewController: UIViewController, EventflitDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let eventflit = Eventflit(key: "APP_KEY")
        eventflit.connection.delegate = self
        // ...
    }
}
```

#### Objective-C
```objc
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.client = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];

    self.client.connection.delegate = self;
    // ...
}
```

Here are examples of setting up a class with functions for each of the optional protocol functions:

#### Swift
```swift
class DummyDelegate: EventflitDelegate {
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // ...
    }

    func debugLog(message: String) {
        // ...
    }

    func subscribedToChannel(name: String) {
        // ...
    }

    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        // ...
    }
}
```

#### Objective-C
```objc
@interface DummyDelegate : NSObject <EventflitDelegate>

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_
- (void)debugLogWithMessage:(NSString *)message
- (void)subscribedToChannelWithName:(NSString *)name
- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error

@end

@implementation DummyDelegate

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_ {
    // ...
}

- (void)debugLogWithMessage:(NSString *)message {
    // ...
}

- (void)subscribedToChannelWithName:(NSString *)name {
    // ...
}

- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error {
    // ...
}

@end
```

The different states that the connection can be in are (Objective-C integer enum cases in brackets):

* `connecting (0)` - the connection is about to attempt to be made
* `connected (1)` - the connection has been successfully made
* `disconnecting (2)` - the connection has been instructed to disconnect and it is just about to do so
* `disconnected (3)` - the connection has disconnected and no attempt will be made to reconnect automatically
* `reconnecting (4)` - an attempt is going to be made to try and re-establish the connection

There is a `stringValue()` function that you can call on `ConnectionState` objects in order to get a `String` representation of the state, for example `"connecting"`.


### Reconnection

There are three main ways in which a disconnection can occur:

  * The client explicitly calls disconnect and a close frame is sent over the websocket connection
  * The client experiences some form of network degradation which leads to a heartbeat (ping/pong) message being missed and thus the client disconnects
  * The Eventflit server closes the websocket connection; typically this will only occur during a restart of the Eventflit socket servers and an almost immediate reconnection should occur

In the case of the first type of disconnection the library will (as you'd hope) not attempt a reconnection.

The library uses [Reachability](https://github.com/ashleymills/Reachability.swift) to attempt to detect network degradation events that lead to disconnection. If this is detected then the library will attempt to reconnect (by default) with an exponential backoff, indefinitely (the maximum time between reconnect attempts is, by default, capped at 120 seconds). The value of `reconnectAttemptsMax` is a public property on the `EventflitConnection` and so can be changed if you wish to set a maximum number of reconnect attempts.

If the Eventflit servers close the websocket, or if a disconnection happens due to nevtwork events that aren't covered by Reachability, then the library will still attempt to reconnect as described above.

All of this is the case if you have the client option of `autoReconnect` set as `true`, which it is by default. If the reconnection strategies are not suitable for your use case then you can set `autoReconnect` to `false` and implement your own reconnection strategy based on the connection state changes.

There are a couple of properties on the connection (`EventflitConnection`) that you can set that affect how the reconnection behaviour works. These are:

* `public var reconnectAttemptsMax: Int? = 6` - if you set this to `nil` then there is no maximum number of reconnect attempts and so attempts will continue to be made with an exponential backoff (based on number of attempts), otherwise only as many attempts as this property's value will be made before the connection's state moves to `.disconnected`
* `public var maxReconnectGapInSeconds: Double? = nil` - if you want to set a maximum length of time (in seconds) between reconnect attempts then set this property appropriately

Note that the number of reconnect attempts gets reset to 0 as soon as a successful connection is made.

## Subscribing

### Public channels

The default method for subscribing to a channel involves invoking the `subscribe` method of your client object:

#### Swift
```swift
let myChannel = eventflit.subscribe("my-channel")
```

#### Objective-C
```objc
EventflitChannel *myChannel = [eventflit subscribeWithChannelName:@"my-channel"];
```

This returns EventflitChannel object, which events can be bound to.

### Private channels

Private channels are created in exactly the same way as public channels, except that they reside in the 'private-' namespace. This means prefixing the channel name:

#### Swift
```swift
let myPrivateChannel = eventflit.subscribe("private-my-channel")
```

#### Objective-C
```objc
EventflitChannel *myPrivateChannel = [eventflit subscribeWithChannelName:@"private-my-channel"];
```

Subscribing to private channels involves the client being authenticated. See the [Configuration](#configuration) section for the authenticated channel example for more information.

### Presence channels

Presence channels are channels whose names are prefixed by `presence-`.

The recommended way of subscribing to a presence channel is to use the `subscribeToPresenceChannel` function, as opposed to the standard `subscribe` function. Using the `subscribeToPresenceChannel` function means that you get a `EventflitPresenceChannel` object returned, as opposed to a standard `EventflitChannel`. This `EventflitPresenceChannel` object has some extra, presence-channel-specific functions availalbe to it, such as `members`, `me`, and `findMember`.

#### Swift
```swift
let myPresenceChannel = eventflit.subscribeToPresenceChannel(channelName: "presence-my-channel")
```

#### Objective-C
```objc
EventflitPresenceChannel *myPresenceChannel = [eventflit subscribeToPresenceChannelWithChannelName:@"presence-my-channel"];
```

As alluded to, you can still subscribe to presence channels using the `subscribe` method, but the channel object you get back won't have access to the presence-channel-specific functions, unless you choose to cast the channel object to a `EventflitPresenceChannel`.

#### Swift
```swift
let myPresenceChannel = eventflit.subscribe("presence-my-channel")
```

#### Objective-C
```objc
EventflitChannel *myPresenceChannel = [eventflit subscribeWithChannelName:@"presence-my-channel"];
```

You can also provide functions that will be called when members are either added to or removed from the channel. These are available as parameters to both `subscribe` and `subscribeToPresenceChannel`.

#### Swift
```swift
let onMemberChange = { (member: EventflitPresenceChannelMember) in
    print(member)
}

let chan = eventflit.subscribeToPresenceChannel("presence-channel", onMemberAdded: onMemberChange, onMemberRemoved: onMemberChange)
```

#### Objective-C
```objc
void (^onMemberChange)(EventflitPresenceChannelMember*) = ^void (EventflitPresenceChannelMember *member) {
    NSLog(@"%@", member);
};

EventflitChannel *myPresenceChannel = [eventflit subscribeWithChannelName:@"presence-my-channel" onMemberAdded:onMemberChange onMemberRemoved:onMemberChange];
```

**Note**: The `members` and `myId` properties of `EventflitPresenceChannel` objects (and functions that get the value of these properties) will only be set once subscription to the channel has succeeded.

The easiest way to find out when a channel has been successfully susbcribed to is to bind to the event named `eventflit:subscription_succeeded` on the channel you're interested in. It would look something like this:

#### Swift
```swift
let eventflit = Eventflit(key: "YOUR_APP_KEY")

let chan = eventflit.subscribeToPresenceChannel("presence-channel")

chan.bind(eventName: "eventflit:subscription_succeeded", callback: { data in
    print("Subscribed!")
    print("I can now access myId: \(chan.myId)")
    print("And here are the channel members: \(chan.members)")
})
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
EventflitPresenceChannel *chan = [eventflit subscribeToPresenceChannelWithChannelName:@"presence-channel"];

[chan bindWithEventName:@"eventflit:subscription_succeeded" callback: ^void (NSDictionary *data) {
    NSLog(@"Subscribed!");
    NSLog(@"I can now access myId: %@", chan.myId);
    NSLog(@"And here are my channel members: %@", chan.members);
}];
```

You can also be notified of a successfull subscription by using the `subscriptionDidSucceed` delegate method that is part of the `EventflitDelegate` protocol.

Here is an example of using the delegate:

#### Swift
```swift
class DummyDelegate: EventflitDelegate {
    func subscribedToChannel(name: String) {
        if channelName == "presence-channel" {
            if let presChan = eventflit.connection.channels.findPresence(channelName) {
                // in here you can now have access to the channel's members and myId properties
                print(presChan.members)
                print(presChan.myId)
            }
        }
    }
}

let eventflit = Eventflit(key: "YOUR_APP_KEY")
eventflit.connection.delegate = DummyDelegate()
let chan = eventflit.subscribeToPresenceChannel("presence-channel")
```

#### Objective-C
```objc
@implementation DummyDelegate

- (void)subscribedToChannelWithName:(NSString *)name {
    if ([channelName isEqual: @"presence-channel"]) {
        EventflitPresenceChannel *presChan = [self.client.connection.channels findPresenceWithName:@"presence-channel"];
        NSLog(@"%@", [presChan members]);
        NSLog(@"%@", [presChan myId]);
    }
}

@implementation ViewController

- (void)viewDidLoad {
    // ...

    Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
    eventflit.connection.delegate = [[DummyDelegate alloc] init];
    EventflitChannel *chan = [eventflit subscribeToPresenceChannelWithChannelName:@"presence-channel"];
```

Note that both private and presence channels require the user to be authenticated in order to subscribe to the channel. This authentication can either happen inside the library, if you configured your Eventflit object with your app's secret, or an authentication request is made to an authentication endpoint that you provide, again when instantiaing your Eventflit object.

We recommend that you use an authentication endpoint over including your app's secret in your app in the vast majority of use cases. If you are completely certain that there's no risk to you including your app's secret in your app, for example if your app is just for internal use at your company, then it can make things easier than setting up an authentication endpoint.


### Subscribing with self-provided auth values

It is possible to subscribe to channels that require authentication by providing the auth information at the point of calling `subscribe` or `subscribeToPresenceChannel`. This is done as shown below:

#### Swift

```swift
let eventflitAuth = EventflitAuth(auth: yourAuthString, channelData: yourOptionalChannelDataString)
let chan = self.eventflit.subscribe(channelName, auth: eventflitAuth)
```

This EventflitAuth object can be initialised with just an auth (String) value if the subscription is to a private channel, or both an `auth (String)` and `channelData (String)` pair of values if the subscription is to a presence channel.

These `auth` and `channelData` values are the values that you received if the json object created by a call to eventflit.authenticate(...) in one of our various server libraries.

Keep in mind that in order to generate a valid auth value for a subscription the `socketId` (i.e. the unique identifier for a web socket connection to the Eventflit servers) must be present when the auth value is generated. As such, the likely flow for using this is something like this would involve checking for when the connection state becomes `connected` before trying to subscribe to any channels requiring authentication.


## Binding to events

Events can be bound to at 2 levels; globally and per channel. When binding to an event you can choose to save the return value, which is a unique identifier for the event handler that gets created. The only reason to save this is if you're going to want to unbind from the event at a later point in time. There is an example of this below.

### Global events

You can attach behaviour to these events regardless of the channel the event is broadcast to. The following is an example of an app that binds to new comments from any channel (that you are subscribed to):

#### Swift
```swift
let eventflit = Eventflit(key: "YOUR_APP_KEY")
eventflit.subscribe("my-channel")

eventflit.bind(callback: { (data: Any?) -> Void in
    if let data = data as? [String : AnyObject] {
        if let commenter = data["commenter"] as? String, message = data["message"] as? String {
            print("\(commenter) wrote \(message)")
        }
    }
})
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
EventflitChannel *chan = [eventflit subscribeWithChannelName:@"my-channel"];

[eventflit bind: ^void (NSDictionary *data) {
    NSString *commenter = data[@"commenter"];
    NSString *message = data[@"message"];

    NSLog(@"%@ wrote %@", commenter, message);
}];
```

### Per-channel events

These are bound to a specific channel, and mean that you can reuse event names in different parts of your client application. The following might be an example of a stock tracking app where several channels are opened for different companies:

#### Swift
```swift
let eventflit = Eventflit(key: "YOUR_APP_KEY")
let myChannel = eventflit.subscribe("my-channel")

myChannel.bind(eventName: "new-price", callback: { (data: Any?) -> Void in
    if let data = data as? [String : AnyObject] {
        if let price = data["price"] as? String, company = data["company"] as? String {
            print("\(company) is now priced at \(price)")
        }
    }
})
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
EventflitChannel *chan = [eventflit subscribeWithChannelName:@"my-channel"];

[chan bindWithEventName:@"new-price" callback:^void (NSDictionary *data) {
    NSString *price = data[@"price"];
    NSString *company = data[@"company"];

    NSLog(@"%@ is now priced at %@", company, price);
}];
```

### Receiving errors

Errors are sent to the client for which they are relevant with an event name of `eventflit:error`. These can be received and handled using code as follows. Obviously the specifics of how to handle them are left up to the developer but this displays the general pattern.

#### Swift
```swift
eventflit.bind({ (message: Any?) in
    if let message = message as? [String: AnyObject], eventName = message["event"] as? String where eventName == "eventflit:error" {
        if let data = message["data"] as? [String: AnyObject], errorMessage = data["message"] as? String {
            print("Error message: \(errorMessage)")
        }
    }
})
```

#### Objective-C
```objc
[eventflit bind:^void (NSDictionary *data) {
    NSString *eventName = data[@"event"];

    if ([eventName isEqualToString:@"eventflit:error"]) {
        NSString *errorMessage = data[@"data"][@"message"];
        NSLog(@"Error message: %@", errorMessage);
    }
}];
```


The sort of errors you might get are:

```bash
# if attempting to subscribe to an already subscribed-to channel

"{\"event\":\"eventflit:error\",\"data\":{\"code\":null,\"message\":\"Existing subscription to channel presence-channel\"}}"

# if the auth signature generated by your auth mechanism is invalid

"{\"event\":\"eventflit:error\",\"data\":{\"code\":null,\"message\":\"Invalid signature: Expected HMAC SHA256 hex digest of 200557.5043858:presence-channel:{\\\"user_id\\\":\\\"200557.5043858\\\"}, but got 8372e1649cf5a45a2de3cd97fe11d85de80b214243e3a9e9f5cee502fa03f880\"}}"
```

You can see that the general form they take is:

```bash
{
  "event": "eventflit:error",
  "data": {
    "code": null,
    "message": "Error message here"
  }
}
```


### Unbind event handlers

You can remove previously-bound handlers from an object by using the `unbind` function. For example,

#### Swift
```swift
let eventflit = Eventflit(key: "YOUR_APP_KEY")
let myChannel = eventflit.subscribe("my-channel")

let eventHandlerId = myChannel.bind(eventName: "new-price", callback: { (data: Any?) -> Void in
  ...
})

myChannel.unbind(eventName: "new-price", callbackId: eventHandlerId)
```

#### Objective-C
```objc
Eventflit *eventflit = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];
EventflitChannel *chan = [eventflit subscribeWithChannelName:@"my-channel"];

NSString *callbackId = [chan bindWithEventName:@"new-price" callback:^void (NSDictionary *data) {
    ...
}];

[chan unbindWithEventName:@"new-price" callbackId:callbackId];
```

You can unbind from events at both the global and per channel level. For both objects you also have the option of calling `unbindAll`, which, as you can guess, will unbind all eventHandlers on the object.


## Push notifications

Eventflit also supports push notifications. Instances of your application can register for push notifications and subscribe to "interests". Your server can then publish to those interests, which will be delivered to your application as push notifications. See [our guide to setting up APNs push notifications](https://docs.eventflit.com/push_notifications/ios) for a friendly introduction.

### Initializing the Eventflit object

You should set up your app for push notifications in your `AppDelegate`. The setup varies slightly depending on whether you're using Swift or Objective-C, and whether you're using iOS or macOS (OS X):

#### Swift on iOS
```swift
import EventflitSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let eventflit = Eventflit(key: "YOUR_APP_KEY")
    ...
```

#### Objective-C on iOS
```objc
#import "AppDelegate.h"
@import UserNotifications;

@interface AppDelegate ()

@end

@implementation AppDelegate
...
```

#### Swift on macOS

```swift
import Cocoa
import EventflitSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, EventflitDelegate {
    let eventflit = Eventflit(key: "YOUR_APP_KEY")
    // ...
```

### Registering with APNs

For your app to receive push notifications, it must first register with APNs. You should do this when the application finishes launching. Your app should register for all types of notification, like so:

#### Swift on iOS
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
        // Enable or disable features based on authorization.
    }
    application.registerForRemoteNotifications()

    return true
}
```

#### Objective-C on iOS
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.eventflit = [[Eventflit alloc] initWithKey:@"YOUR_APP_KEY"];

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Enable or disable features based on authorization.
    }];

    [application registerForRemoteNotifications];
    return YES;
}
```

#### Swift on macOS

```swift
func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.registerForRemoteNotifications(matching: [NSRemoteNotificationType.alert, NSRemoteNotificationType.sound, NSRemoteNotificationType.badge])
}
```

### Receiving your APNs device token and registering with Eventflit

Next, APNs will respond with a device token identifying your app instance. Your app should then register with Eventflit, passing along its device token.

Your app can now subscribe to interests. The following registers and subscribes the app to the interest "donuts":

#### Swift on iOS
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    eventflit.nativeEventflit.register(deviceToken: deviceToken)
    eventflit.nativeEventflit.subscribe(interestName: "donuts")
}
```

#### Objective-C on iOS
```objc
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Registered for remote notifications; received device token");
    [[[self eventflit] nativeEventflit] registerWithDeviceToken:deviceToken];
    [[[self eventflit] nativeEventflit] subscribeWithInterestName:@"donuts"];
}
```

#### Swift on macOS
```swift
func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    self.eventflit.nativeEventflit.register(deviceToken: deviceToken)
    self.eventflit.nativeEventflit.subscribe(interestName: "donuts")
}
```


### Receiving push notifications

When your server publishes a notification to the interest "donuts", it will get passed to your app. This happens as a call in your `AppDelegate` which you should listen to:

#### Swift on iOS
```swift
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print(userInfo)
}
```

#### Objective-C on iOS
```objc
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Received remote notification: %@", userInfo);
}
```

#### Swift on macOS
```swift
func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
    print("Received remote notification: \(userInfo.debugDescription)" )
}
```


### Unsubscribing from interests

If at a later point you wish to unsubscribe from an interest, this works in the same way:

#### Swift
```swift
eventflit.nativeEventflit.unsubscribe(interestName: "donuts")
```

#### Objective-C
```objc
[[[self eventflit] nativeEventflit] unsubscribeWithInterestName:@"donuts"];
```

For a complete example of a working app, see the [Example/](https://github.com/eventflit/eventflit-websocket-swift/tree/push-notifications/Example) directory in this repository. Specifically for push notifications code, see the [Example/AppDelegate.swift](https://github.com/eventflit/eventflit-websocket-swift/blob/master/iOS%20Example%20Swift/iOS%20Example%20Swift/AppDelegate.swift) file.


### Eventflit delegate

You can also implement some of the `EventflitDelegate` functions to get access to events that occur in relation to push notifications interactions. These are the functions that you can optionally implement when conforming to the `EventflitDelegate` protocol:

```swift
@objc optional func registeredForPushNotifications(clientId: String)
@objc optional func failedToRegisterForPushNotifications(response: URLResponse, responseBody: String?)
@objc optional func subscribedToInterest(name: String)
@objc optional func unsubscribedFromInterest(name: String)
```

Again, the names of the functions largely give away what their purpose is but just for completeness:

- `registeredForPushNotifications` - use this if you want to know when a client has successfully registered with the Eventflit Push Notifications service, or if you want access to the `clientId` that is returned upon successful registration
- `failedToRegisterForPushNotifications` - use this if you want to know when a client has failed to register with the Eventflit Push Notifications service
- `subscribedToInterest` - use this if you want keep track of interests that are successfully subscribed to
- `unsubscribedFromInterest` - use this if you want keep track of interests that are successfully unsubscribed from

Setting up a delegate looks like this:

#### Swift
```swift
class ViewController: UIViewController, EventflitDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let eventflit = Eventflit(key: "APP_KEY")
        eventflit.delegate = self
        // ...
    }
}
```

#### Objective-C
```objc
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.client = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY"];

    self.client.delegate = self;
    // ...
}
```

The process is identical to that of setting up the `EventflitDelegate` to receive notifications of connection-based events.


## Testing

There are a set of tests for the library that can be run using the standard method (Command-U in Xcode).


## Communication

- If you have found a bug, please open an issue.
- If you have a feature request, please open an issue.
- If you want to contribute, please submit a pull request (preferrably with some tests 🙂 ).


## Credits

EventflitSwift is owned and maintained by [Eventflit](https://eventflit.com). It was originally created by [Hamilton Chapman](https://github.com/hamchapman).

It uses code from the following repositories:

* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
* [Reachability.swift](https://github.com/ashleymills/Reachability.swift)
* [Starscream](https://github.com/daltoniam/Starscream)

The individual licenses for these libraries are included in the corresponding Swift files.


## License

EventflitSwift is released under the MIT license. See [LICENSE](https://github.com/eventflit/eventflit-websocket-swift/blob/master/LICENSE.md) for details.
