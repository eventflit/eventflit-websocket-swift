import Foundation
import TaskQueue

#if os(iOS) || os(OSX)

/**
    An interface to Eventflit's native push notification service.
    The service is a pub-sub system for push notifications.
    Notifications are published to "interests".
    Clients (such as this app instance) subscribe to those interests.

    A per-app instance NativeEventflit is available via an instance of Eventflit.
*/
@objcMembers
@objc open class NativeEventflit: NSObject {
    private static let PLATFORM_TYPE = "apns"
    private let CLIENT_API_V1_ENDPOINT = "https://push.eventflit.com"
    private let LIBRARY_NAME_AND_VERSION = "eventflit-websocket-swift " + VERSION

    public var URLSession = Foundation.URLSession.shared
    private var failedRequestAttempts: Int = 0
    private let maxFailedRequestAttempts: Int = 6

    internal weak var delegate: EventflitDelegate? = nil

    internal var requestQueue = TaskQueue()

    /**
        Identifies a Eventflit app, which should have push notifications enabled
        and a certificate added for the push notifications to work
    */
    private var eventflitAppKey: String? = nil

    /**
        The id issued to this app instance by Eventflit, which is received upon
        registrations. It's used to identify a client when subscribe /
        unsubscribe requests are made
    */
    internal var clientId: String? = nil

    /**
        Normal clients should access the instance via Eventflit.nativeEventflit()
    */
    internal override init() {}

    /**
        Sets the eventflitAppKey property and then attempts to flush
        the outbox of any pending requests

        - parameter eventflitAppKey: The Eventflit app key
    */
    open func setEventflitAppKey(eventflitAppKey: String) {
        self.eventflitAppKey = eventflitAppKey

        if self.clientId != nil {
            requestQueue.run()
        }
    }

    /**
        Makes device token presentable to server

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as Data

        - returns: the deviceToken formatted as a String
    */
    private func deviceTokenToString(deviceToken: Data) -> String {
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        return deviceTokenString
    }

    /**
        Registers (asynchronously) this app instance with Eventflit for push notifications.
        This must be done before we can subscribe to interests.

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as Data
    */
    open func register(deviceToken: Data) {
        var request = URLRequest(url: URL(
            string: CLIENT_API_V1_ENDPOINT + "/device/app/" + eventflitAppKey + "/" + PLATFORM_TYPE
        )!)
        request.httpMethod = "POST"
        let deviceTokenString = deviceTokenToString(deviceToken: deviceToken)

        let params: [String: Any] = [
            "appKey": eventflitAppKey!,
            "token": deviceTokenString
        ]

        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(LIBRARY_NAME_AND_VERSION, forHTTPHeaderField: "X-Eventflit-Library" )

        let task = URLSession.dataTask(with: request, completionHandler: { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
                   (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                        /**
                            We only care about the "id" value, which is our new client id.
                            We store our id so that we can use it to subscribe/unsubscribe.
                        */
                        if let clientIdJson = try! JSONSerialization.jsonObject(with: data!, options: [])
                                      as? [String: AnyObject] {
                            if clientIdJson {
                                if let clientId = clientIdJson as? String {
                                    self.clientId = clientId
                                    self.delegate?.registeredForPushNotifications?(clientId: clientId)
                                    self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Successfully registered for push notifications and got clientId: \(clientId)")
                                    self.requestQueue.run()
                                } else {
                                    self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] \"id\" in JSON response was not a string: \(json)")
                                }
                            } else {
                                self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] No \"id\" from JSON response: \(json)")
                            }
                        } else {
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Could not parse body as JSON object: \(String(describing: data))")
                        }
            } else {
                if data != nil && response != nil {
                    let responseBody = String(data: data!, encoding: .utf8)
                    self.delegate?.failedToRegisterForPushNotifications?(response: response!, responseBody: responseBody)
                    self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Bad HTTP response: \(response!) with body: \(String(describing: responseBody))")
                }
            }
        })

        task.resume()
    }

    /**
        Subscribe to an interest with Eventflit's Push Notification Service

        - parameter interestName: the name of the interest you want to subscribe to
    */
    open func subscribe(interestName: String) {
        addSubscriptionChangeToTaskQueue(interestName: interestName, change: .subscribe)
    }

    /**
     Subscribe to interests with Eventflit's Push Notification Service

     - parameter interests: the name of the interests you want to subscribe to
     */
    open func setSubscriptions(interests: Array<String>) {
        requestQueue.tasks += { _, next in
            self.replaceSubscriptionSet(
                interests: interests,
                successCallback: next
            )
        }
        
        requestQueue.run()
    }

    /**
        Unsubscribe from an interest with Eventflit's Push Notification Service

        - parameter interestName: the name of the interest you want to unsubscribe
                                  from
    */
    open func unsubscribe(interestName: String) {
        addSubscriptionChangeToTaskQueue(interestName: interestName, change: .unsubscribe)
    }

    /**
        Adds subscribe / unsubscribe tasts to task queue

        - parameter interestName: the name of the interest you want to interact with
        - parameter change:       specifies whether the change is to subscribe or
                                  unsubscribe

    */
    private func addSubscriptionChangeToTaskQueue(interestName: String, change: SubscriptionChange) {
        requestQueue.tasks += { _, next in
            self.subscribeOrUnsubscribeInterest(
                interest: interestName,
                change: change,
                successCallback: next
            )
        }

        requestQueue.run()
    }

    /**
        Makes either a POST or DELETE request for a given interest
        - parameter interest:     The name of the interest to be subscribed to / unsunscribed from
        - parameter change:       Whether to subscribe or unsubscribe
        - parameter callback:     Callback to be called upon success
    */
    private func subscribeOrUnsubscribeInterest(interest: String, change: SubscriptionChange, successCallback: @escaping (Any?) -> Void) {
        guard
            let clientId = clientId,
            let eventflitAppKey = eventflitAppKey
        else {
            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] eventflitAppKey or clientId not set - waiting for both to be set")
            self.requestQueue.pauseAndResetCurrentTask()
            return
        }

        let url = "\(CLIENT_API_V1_ENDPOINT)/device/app/\(eventflitAppKey)/\(PLATFORM_TYPE)/\(clientId)/interests/\(interest)"
        let params: [String: Any] = ["appKey": eventflitAppKey]
        let request = self.setRequest(url: url, params: params, change: change)
        self.doURLRequest(interests: [interest], request: request, change: change, successCallback: successCallback)
    }

    /**
     Makes a PUT request for given interests
     - parameter interests:    The name of the interests to be subscribed to
     - parameter callback:     Callback to be called upon success
     */
    private func replaceSubscriptionSet(interests: Array<String>, successCallback: @escaping (Any?) -> Void) {
        guard
            let clientId = clientId,
            let eventflitAppKey = eventflitAppKey
        else {
            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] eventflitAppKey or clientId not set - waiting for both to be set")
            self.requestQueue.pauseAndResetCurrentTask()
            return
        }

        let url = "\(CLIENT_API_V1_ENDPOINT)/device/app/\(eventflitAppKey)/\(PLATFORM_TYPE)/\(clientId)/interests/"
        let params: [String: Any] = ["appKey": eventflitAppKey, "interests": interests]
        let request = self.setRequest(url: url, params: params, change: .setSubscriptions)
        self.doURLRequest(interests: interests, request: request, change: .setSubscriptions, successCallback: successCallback)
    }

    private func doURLRequest(interests: Array<String>, request: URLRequest, change: SubscriptionChange, successCallback: @escaping (Any?) -> Void) {
        self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Attempt number: \(self.failedRequestAttempts + 1) of \(maxFailedRequestAttempts)")

        let task = URLSession.dataTask(
            with: request,
            completionHandler: { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse,
                    (200 <= httpResponse.statusCode && httpResponse.statusCode < 300) &&
                        error == nil
                    else {
                        self.failedRequestAttempts += 1

                        if error != nil {
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Error when trying to modify subscription to interest(s): \(String(describing: error?.localizedDescription))")
                        } else if data != nil && response != nil {
                            let responseBody = String(data: data!, encoding: .utf8)
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Bad response from server: \(response!) with body: \(String(describing: responseBody))")
                        } else {
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Bad response from server when trying to modify subscription to interest(s): \(interests)")
                        }

                        if self.failedRequestAttempts >= self.maxFailedRequestAttempts {
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Max number of failed native service requests reached")

                            self.requestQueue.paused = true
                        } else {
                            self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Retrying subscription modification request for interest(s): \(interests)")
                            self.requestQueue.retry(Double(self.failedRequestAttempts * self.failedRequestAttempts))
                        }

                        return
                }

                switch change {
                case .subscribe:
                    guard let interest = interests.first else { return }
                    self.delegate?.subscribedToInterest?(name: interest)
                case .setSubscriptions:
                    self.delegate?.subscribedToInterests?(interests: interests)
                case .unsubscribe:
                    guard let interest = interests.first else { return }
                    self.delegate?.unsubscribedFromInterest?(name: interest)
                }

                self.delegate?.debugLog?(message: "[EVENTFLIT DEBUG] Success making \(change.rawValue) to \(interests)")

                self.failedRequestAttempts = 0
                successCallback(nil)
        }
        )

        task.resume()
    }

    private func setRequest(url: String, params: [String: Any], change: SubscriptionChange) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = change.httpMethod()

        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(LIBRARY_NAME_AND_VERSION, forHTTPHeaderField: "X-Eventflit-Library")

        return request
    }
}

internal enum SubscriptionChange: String {
    case subscribe
    case setSubscriptions
    case unsubscribe

    internal func httpMethod() -> String {
        switch self {
        case .subscribe:
            return "POST"
        case .setSubscriptions:
            return "PUT"
        case .unsubscribe:
            return "DELETE"
        }
    }
}

#endif
