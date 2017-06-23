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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        tamaEmuRegisterUserDefaults()
        emulator = TamaEmulatorController()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        emulator?.isPaused = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        emulator?.isPaused = false
        emulator?.runFrameAsync()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        emulator?.isPaused = true
        emulator = nil
    }

}
