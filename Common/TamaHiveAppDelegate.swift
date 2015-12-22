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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        tamaRegisterUserDefaults()
        dataController = TamaDataController()
        return true
    }

    // MARK: Application Delegate callbacks

    func applicationDidBecomeActive(application: UIApplication) {
        dataController?.fetchData()
    }

    func applicationWillResignActive(application: UIApplication) {
        dataController?.stopFetching()
    }

}

