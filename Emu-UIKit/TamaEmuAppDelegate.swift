//
//  TamaEmuAppDelegate.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

@UIApplicationMain
class TamaEmuAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var emulator: TamaEmulatorController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.emulator = TamaEmulatorController()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        self.emulator?.isPaused = true
        self.emulator?.saveEeprom()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        self.emulator?.isPaused = true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        self.emulator?.isPaused = false
        self.emulator?.runFrameAsync()
    }

    func applicationWillTerminate(application: UIApplication) {
        self.emulator?.isPaused = true
        self.emulator?.saveEeprom()
        self.emulator = nil
    }

}
