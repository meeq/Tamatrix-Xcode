//
//  ExtensionDelegate.swift
//  Tama-Hive-Watch Extension
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import WatchKit

let TamaDataURL = "http://tamahive.spritesserver.nl/gettama.php"

class TamaExtensionDelegate: NSObject, WKExtensionDelegate {

    var dataController: TamaDataController?
    var tamaData = [Int: NSDictionary]()

    func applicationDidFinishLaunching() {
        dataController = TamaDataController(url: TamaDataURL)
        dataController!.fetchData()
        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    func tamaDataDidUpdate(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            let oldData = self.tamaData
            let newData = sender.object as! [Int: NSDictionary]
            self.tamaData = newData
            if oldData.count != newData.count {
                self.reloadRootControllers()
            }
        }
    }

    func reloadRootControllers() {
        let controllers = [String](count: self.tamaData.count, repeatedValue: "TamaInterfaceController")
        let contexts = self.tamaData.keys.sort()
        WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: contexts)
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        dataController?.fetchData()
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        dataController?.stopFetchTimer()
    }

}
