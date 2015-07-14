//
//  AppDelegate.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/7/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

struct GPXURL {
    static let Notification = "GPX Broadcaster"
    static let Key = "GPXURL"
}
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    /**
        - Note: sets up a notification channel to broadcast the URL of a dropped file
    */
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: GPXURL.Notification, object: self, userInfo: [GPXURL.Key:url])
        center.postNotification(notification)
        return true
    }
}

