//
//  TamaDataController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

let tamaDefaultDataURL = "http://tamahive.spritesserver.nl/gettama.php"
let TamaDataUpdateNotificationKey = "com.christopherbonhage.tamaDataUpdateNotification"

class TamaDataController: NSObject {

    var baseUrl: String
    var lastseq: Int = 0
    var tamaData: [Int: NSDictionary]
    
    var fetchTimer: NSTimer?
    var fetchInterval: NSTimeInterval = 0.35
    var fetchRepeats: Bool = true

    init(url: String) {
        self.baseUrl = url
        self.tamaData = [Int: NSDictionary]()
    }

    convenience override init() {
        self.init(url: tamaDefaultDataURL)
    }

    func startFetchTimer() {
        self.stopFetching()
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
    }

    func fetchData() {
        var urlString = self.baseUrl
        if lastseq > 0 {
            urlString = "\(urlString)?lastseq=\(lastseq)"
        }
        print("Fetching data from \(urlString)")
        let url = NSURL(string: urlString)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { data, response, error in
            guard data != nil else {
                print("Request failed: \(error)")
                return
            }
            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            if jsonStr == "" {
                // Sometimes the response comes back blank; just ignore it and try again later.
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
        if self.fetchRepeats {
            self.startFetchTimer()
        }
    }

}