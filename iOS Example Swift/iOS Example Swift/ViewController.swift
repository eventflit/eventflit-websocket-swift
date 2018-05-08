//
//  ViewController.swift
//  iOS Example
//
//  Created by Hamilton Chapman on 24/02/2015.
//  Copyright (c) 2015 Eventflit. All rights reserved.
//

import UIKit
import EventflitSwift

class ViewController: UIViewController, EventflitDelegate {
    var eventflit: Eventflit! = nil

    @IBAction func connectButton(_ sender: AnyObject) {
        eventflit.connect()
    }

    @IBAction func disconnectButton(_ sender: AnyObject) {
        eventflit.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only use your secret here for testing or if you're sure that there's
        // no security risk
//        let eventflitClientOptions = EventflitClientOptions(authMethod: .inline(secret: "YOUR_APP_SECRET"))
//        eventflit = Eventflit(key: "YOUR_APP_KEY", options: eventflitClientOptions)

//        // Use this if you want to try out your auth endpoint
//        let optionsWithEndpoint = EventflitClientOptions(
//            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
//        )
//        eventflit = Eventflit(key: "YOUR_APP_KEY", options: optionsWithEndpoint)

        // Use this if you want to try out your auth endpoint (deprecated method)

        eventflit.delegate = self

        eventflit.connect()

        let _ = eventflit.bind({ (message: Any?) in
            if let message = message as? [String: AnyObject], let eventName = message["event"] as? String, eventName == "eventflit:error" {
                if let data = message["data"] as? [String: AnyObject], let errorMessage = data["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
        })

        let onMemberAdded = { (member: EventflitPresenceChannelMember) in
            print(member)
        }

        let chan = eventflit.subscribe("presence-channel", onMemberAdded: onMemberAdded)

        let _ = chan.bind(eventName: "test-event", callback: { data in
            print(data)
            let _ = self.eventflit.subscribe("presence-channel", onMemberAdded: onMemberAdded)

            if let data = data as? [String : AnyObject] {
                if let testVal = data["test"] as? String {
                    print(testVal)
                }
            }
        })

        // triggers a client event
        chan.trigger(eventName: "client-test", data: ["test": "some value"])
    }

    // EventflitDelegate methods

    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // print the old and new connection states
        print("old: \(old.stringValue()) -> new: \(new.stringValue())")
    }

    func subscribedToChannel(name: String) {
        print("Subscribed to \(name)")
    }

    func debugLog(message: String) {
        print(message)
    }
}


class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/eventflit/auth")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
        return request
    }
}
