//
//  TamaExtensionDelegate.swift
//  Tama-Hive-Watch Extension
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import WatchKit

class TamaExtensionDelegate: NSObject, WKExtensionDelegate {

    private var dataController: TamaDataController?
    private var tamaData = [Int: TamaModel]()
    private var pageCount: Int = 0

    func applicationDidFinishLaunching() {
        tamaRegisterUserDefaults()
        dataController = TamaDataController()
        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    func tamaDataDidUpdate(sender: AnyObject) {
        self.tamaData = sender.object as! [Int: TamaModel]
        if self.pageCount != self.tamaData.count {
            self.reloadRootControllers()
        }
    }

    func reloadRootControllers() {
        self.pageCount = self.tamaData.count
        let names = [String](count: self.pageCount, repeatedValue: "TamaInterfaceController")
        var contexts = [TamaModel]()
        for key in self.tamaData.keys.sort() {
            contexts.append(self.tamaData[key]!)
        }
        dispatch_async(dispatch_get_main_queue()) {
            WKInterfaceController.reloadRootControllersWithNames(names, contexts: contexts)
        }
    }

    func applicationDidBecomeActive() {
        dataController?.startFetchTimer()
    }

    func applicationWillResignActive() {
        dataController?.stopFetching()
    }

}
