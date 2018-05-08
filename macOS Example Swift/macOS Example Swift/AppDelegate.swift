//
//  AppDelegate.swift
//  macOS Example Swift
//
//  Created by Hamilton Chapman on 09/11/2016.
//  Copyright © 2016 Eventflit. All rights reserved.
//

import Cocoa
import EventflitSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, EventflitDelegate {

    let eventflit = Eventflit(key: "YOUR_APP_KEY")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.registerForRemoteNotifications(
            matching: [
                NSApplication.RemoteNotificationType.alert,
                NSApplication.RemoteNotificationType.sound,
                NSApplication.RemoteNotificationType.badge
            ]
        );

        self.eventflit.delegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.eventflit.nativeEventflit.register(deviceToken: deviceToken)
        self.eventflit.nativeEventflit.subscribe(interestName: "donuts")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        print("Received remote notification: " + userInfo.debugDescription)
    }

    // MARK: EventflitDelegate

    func subscribedToInterest(name: String) {
        print("Subscribed to interest: \(name)")
    }

    func unsubscribedFromInterest(name: String) {
        print("Unsubscribed from interest: \(name)")
    }

    func registeredForPushNotifications(clientId: String) {
        print("Registered with Eventflit for push notifications with clientId: \(clientId)")
    }

    func debugLog(message: String) {
        print(message)
    }
}
