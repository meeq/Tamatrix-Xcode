//
//  TamaExtensionDelegate.swift
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
        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    func tamaDataDidUpdate(sender: AnyObject) {
        let oldData = self.tamaData
        let newData = sender.object as! [Int: NSDictionary]
        self.tamaData = newData
        if oldData.count != newData.count {
            dispatch_async(dispatch_get_main_queue()) {
                self.reloadRootControllers()
            }
        }
    }

    func reloadRootControllers() {
        let controllers = [String](count: self.tamaData.count, repeatedValue: "TamaInterfaceController")
        let keys = self.tamaData.keys.sort()
        var contexts = [NSDictionary]()
        for key in keys {
            contexts.append(self.tamaData[key]!)
        }
        WKInterfaceController.reloadRootControllersWithNames(controllers, contexts: contexts)
    }

    func applicationDidBecomeActive() {
        // Start timers
        dataController?.fetchData()
    }

    func applicationWillResignActive() {
        // Stop timers
        dataController?.stopFetchTimer()
    }

}
