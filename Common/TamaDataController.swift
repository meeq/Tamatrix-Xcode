//
//  TamaDataController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

let TamaSettingsDataURLKey = "DataURL"
let TamaSettingsDataURLDefault = "http://tamahive.spritesserver.nl/gettama.php"
let TamaSettingsFetchIntervalKey = "FetchInterval"
let TamaSettingsFetchIntervalDefault = 0.2

func tamaRegisterUserDefaults() {
    NSUserDefaults.standardUserDefaults().registerDefaults([
        TamaSettingsDataURLKey: TamaSettingsDataURLDefault,
        TamaSettingsFetchIntervalKey: TamaSettingsFetchIntervalDefault
    ])
}

let TamaDataUpdateNotificationKey = "tamaDataUpdateNotification"

class TamaDataController: NSObject {

    // Fetch state
    private var lastseq: Int = 0
    private var tamaData: [Int: NSDictionary]
    private var fetchTimer: NSTimer?
    private var fetchRepeats: Bool = true

    // Settings
    private var baseUrl: String = TamaSettingsDataURLDefault
    private var fetchInterval: NSTimeInterval = TamaSettingsFetchIntervalDefault

    override init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let configUrl = defaults.stringForKey(TamaSettingsDataURLKey) {
            self.baseUrl = configUrl
        }
        let configInterval = defaults.doubleForKey(TamaSettingsFetchIntervalKey)
        if configInterval > 0 {
            self.fetchInterval = configInterval
        }
        self.tamaData = [Int: NSDictionary]()
        super.init()
    }

    func startFetchTimer() {
        self.stopFetching()
        self.fetchRepeats = true
        self.fetchTimer = NSTimer(
            timeInterval: self.fetchInterval,
            target: self,
            selector: "fetchData",
            userInfo: nil,
            repeats: false)
        NSRunLoop.mainRunLoop().addTimer(self.fetchTimer!, forMode: NSRunLoopCommonModes)
    }

    func stopFetching() {
        self.fetchTimer?.invalidate()
        self.fetchTimer = nil
        self.fetchRepeats = false
    }

    func fetchData() {
        // Build the request URL from the sequence number of the last request
        var urlString = self.baseUrl
        if lastseq > 0 {
            urlString = "\(urlString)?lastseq=\(lastseq)"
        }
#if DEBUG
        print("Fetching data from \(urlString)")
#endif
        let url: NSURL = NSURL(string: urlString)! // TODO Handle bad URLs a bit more elegantly
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
            // TODO Notify the application that a data error has occurred
            guard data != nil else {
                print("Request failed: \(error)")
                return
            }
            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            // Sometimes the response comes back blank; just ignore it and try again.
            if (jsonStr == "") && self.fetchRepeats {
                self.startFetchTimer()
                return
            }
            // Attempt to parse the response as JSON
            do {
                if let jsonObj = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                    self.processResponseDictionary(jsonObj) // Success!
                } else {
                    print("Could not parse JSON Object: \(jsonStr)")
                    // TODO Notify the application that a data error has occurred
                    // TODO Retry?
                }
            } catch let parseError {
                print("Parse error for JSON: \(jsonStr)")
                print(parseError)
                // TODO Notify the application that a data error has occurred
                // TODO Retry?
            }
        }
        task.resume()
    }

    func processResponseDictionary(respObj: NSDictionary) {
        // Grab the useful bits
        // TODO Validate the response object
        self.lastseq = respObj["lastseq"] as! Int
        for tama in respObj["tama"] as! [NSDictionary] {
            let id = tama["id"] as! Int
            self.tamaData[id] = tama
        }
        // Update the rest of the application
        NSNotificationCenter.defaultCenter().postNotificationName(TamaDataUpdateNotificationKey, object: self.tamaData)
        // Keep fetching data periodically unless the timer was stopped.
        if self.fetchRepeats {
            self.startFetchTimer()
        }
    }

}