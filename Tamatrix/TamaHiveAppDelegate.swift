//
//  AppDelegate.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

let TamaDataUpdateNotificationKey = "com.christopherbonhage.tamaDataUpdateNotification"

@UIApplicationMain
class TamaHiveAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var lastseq: Int = 0
    var tamaData: [Int: NSDictionary]!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        self.tamaData = [Int: NSDictionary]()
        self.fetchData()
        return true
    }

    // MARK: Data Helpers

    func startFetchTimer() {
        let timer = NSTimer(timeInterval: 0.5, target: self, selector: "fetchData", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }

    func fetchData() {
        var urlString = "http://127.0.0.1/tamaweb/gettama.php"
        if lastseq > 0 {
            urlString = "\(urlString)?lastseq=\(lastseq)"
        }
        let url = NSURL(string: urlString)
        print("Fetching data: \(url!.absoluteString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { data, response, error in
            guard data != nil else {
                print("Request failed: \(error)")
                return
            }
            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            if jsonStr == "" {
                self.startFetchTimer()
            }
            do {
                if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                    self.processData(json)
                } else {
                    print("Could not parse JSON: \(jsonStr)")
                }
            } catch let parseError {
                print("Parse error for JSON: \(jsonStr)")
                print(parseError)
            }
        }
        task.resume()
    }

    func processData(data: NSDictionary) {
        self.lastseq = data["lastseq"] as! Int
        for entry in data["tama"] as! [NSDictionary] {
            let id = entry["id"] as! Int
            self.tamaData[id] = entry
        }
        NSNotificationCenter.defaultCenter().postNotificationName(TamaDataUpdateNotificationKey, object: self.tamaData)
        self.startFetchTimer()
    }

    // MARK: Application Delegate callbacks

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

