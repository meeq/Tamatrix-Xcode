//
//  TamaHiveAppDelegate.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

@UIApplicationMain
class TamaHiveAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dataController: TamaDataController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        tamaHiveRegisterUserDefaults()
        dataController = TamaDataController()
        return true
    }

    // MARK: Application Delegate callbacks

    func applicationDidBecomeActive(_ application: UIApplication) {
        dataController?.startFetchTimer()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        dataController?.stopFetching()
    }

}

