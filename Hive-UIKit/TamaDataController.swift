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

func tamaHiveRegisterUserDefaults() {
    UserDefaults.standard.register(defaults: [
        TamaSettingsDataURLKey: TamaSettingsDataURLDefault,
        TamaSettingsFetchIntervalKey: TamaSettingsFetchIntervalDefault
    ])
}

let TamaDataUpdateNotificationKey = "tamaDataUpdateNotification"

class TamaModel: NSObject {
    var id: Int
    var pixels: String

    init(id: Int, pixels: String) {
        self.id = id
        self.pixels = pixels
        super.init()
    }
}

class TamaDataController: NSObject {

    // Fetch state
    private var lastseq: Int = 0
    private var tamaData: [Int: TamaModel]
    private var fetchTimer: Timer?
    private var fetchRepeats: Bool = true

    // Settings
    private var baseUrl: String = TamaSettingsDataURLDefault
    private var fetchInterval: TimeInterval = TamaSettingsFetchIntervalDefault

    override init() {
        let defaults = UserDefaults.standard
        if let configUrl = defaults.string(forKey: TamaSettingsDataURLKey) {
            baseUrl = configUrl
        }
        let configInterval = defaults.double(forKey: TamaSettingsFetchIntervalKey)
        if configInterval > 0 {
            fetchInterval = configInterval
        }
        tamaData = [Int: TamaModel]()
        super.init()
    }

    func startFetchTimer() {
        if fetchTimer != nil {
            return
        }
        fetchRepeats = true
        fetchTimer = Timer(
            timeInterval: fetchInterval,
            target: self,
            selector: #selector(TamaDataController.fetchData),
            userInfo: nil,
            repeats: false)
        RunLoop.main.add(fetchTimer!, forMode: RunLoopMode.commonModes)
    }

    func stopFetching() {
        fetchTimer?.invalidate()
        fetchTimer = nil
        fetchRepeats = false
    }

    func fetchData() {
        // Clear possible outstanding timer
        fetchTimer?.invalidate()
        fetchTimer = nil
        // Build the request URL from the sequence number of the last request
        var urlString = baseUrl
        if lastseq > 0 {
            urlString = "\(urlString)?lastseq=\(lastseq)"
        }
        print("Fetching data from \(urlString)")
        let url: URL = URL(string: urlString)! // TODO Handle bad URLs a bit more elegantly
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            // TODO Notify the application that a data error has occurred
            guard data != nil else {
                print("Request failed: \(String(describing: error))")
                return
            }
            let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            // Sometimes the response comes back blank; just ignore it and try again.
            if (jsonStr == "") && self.fetchRepeats {
                self.startFetchTimer()
                return
            }
            // Attempt to parse the response as JSON
            do {
                if let jsonObj = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    self.processResponseDictionary(jsonObj) // Success!
                } else {
                    print("Could not parse JSON Object: \(String(describing: jsonStr))")
                    // TODO Notify the application that a data error has occurred
                    // TODO Retry?
                }
            } catch let parseError {
                print("Parse error for JSON: \(String(describing: jsonStr))")
                print(parseError)
                // TODO Notify the application that a data error has occurred
                // TODO Retry?
            }
        }) 
        task.resume()
    }

    private func processResponseDictionary(_ respObj: NSDictionary) {
        // Grab the useful bits
        // TODO Validate the response object (beyond crashing)
        lastseq = respObj["lastseq"] as! Int
        for tamaDict in respObj["tama"] as! [NSDictionary] {
            let id = tamaDict["id"] as! Int
            let pixels = tamaDict["pixels"] as! String
            if let tamaModel = tamaData[id] {
                tamaModel.pixels = pixels
            } else {
                tamaData[id] = TamaModel(id: id, pixels: pixels)
            }
        }
        // Update the rest of the application
        NotificationCenter.default.post(name: Notification.Name(rawValue: TamaDataUpdateNotificationKey), object: tamaData)
        // Keep fetching data periodically unless the timer was stopped.
        if fetchRepeats {
            startFetchTimer()
        }
    }

}
