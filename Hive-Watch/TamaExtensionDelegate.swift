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
        tamaHiveRegisterUserDefaults()
        dataController = TamaDataController()
        // Listen for data-change events
        NotificationCenter.default.addObserver(self,
            selector: #selector(TamaExtensionDelegate.tamaDataDidUpdate(_:)),
            name: NSNotification.Name(rawValue: TamaDataUpdateNotificationKey),
            object: nil)
    }

    func tamaDataDidUpdate(_ sender: AnyObject) {
        tamaData = sender.object as! [Int: TamaModel]
        if pageCount != tamaData.count {
            reloadRootControllers()
        }
    }

    func reloadRootControllers() {
        pageCount = tamaData.count
        let names = [String](repeating: "TamaInterfaceController", count: pageCount)
        var contexts = [TamaModel]()
        for key in tamaData.keys.sorted() {
            contexts.append(tamaData[key]!)
        }
        DispatchQueue.main.async {
            WKInterfaceController.reloadRootControllers(withNames: names, contexts: contexts)
        }
    }

    func applicationDidBecomeActive() {
        dataController?.startFetchTimer()
    }

    func applicationWillResignActive() {
        dataController?.stopFetching()
    }

}
