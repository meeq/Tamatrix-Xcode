//
//  TamaEmulatorController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

let tamaClock: Int = 16000000
let tamaFps: Int = 15
let tamaRunCycles: Int32 = Int32(tamaClock / tamaFps)
let tamaDramSize: Int = 512

let tamaScreenWidth = 48
let tamaScreenHeight = 32

struct TamaIcons : OptionSetType {
    let rawValue: Int

    static let None         = TamaIcons(rawValue: 0)
    static let Info         = TamaIcons(rawValue: 1 << 0)
    static let Food         = TamaIcons(rawValue: 1 << 1)
    static let Toilet       = TamaIcons(rawValue: 1 << 2)
    static let Door         = TamaIcons(rawValue: 1 << 3)
    static let Figure       = TamaIcons(rawValue: 1 << 4)
    static let Training     = TamaIcons(rawValue: 1 << 5)
    static let Medical      = TamaIcons(rawValue: 1 << 6)
    static let IR           = TamaIcons(rawValue: 1 << 7)
    static let Album        = TamaIcons(rawValue: 1 << 8)
    static let Attention    = TamaIcons(rawValue: 1 << 9)
}

class TamaEmulatorController: NSObject {

    var tamaPointer: UnsafeMutablePointer<Tamagotchi>?
    var tama: Tamagotchi?
    var dram = [UInt8](count: tamaDramSize, repeatedValue: 0)
    var display = Display()
    var microSecs: UInt = 0
    var frameCount: UInt = 0
    var isAIEnabled: Bool = true

    override init() {
        super.init()
        let romData = loadRoms(self.romDataPath()!)
        self.tamaPointer = tamaInit(romData, self.eepromPath()!)
        self.tama = self.tamaPointer!.memory
    }

    deinit {
        guard self.tamaPointer != nil else {
            return
        }
        tamaDeinit(self.tamaPointer!)
        self.tama = nil
    }

    func romDataPath() -> [CChar]? {
        // TODO Make this configurable
        let bundle = NSBundle.mainBundle()
        if let romDirStr = bundle.pathForResource("rom", ofType: nil) {
            return romDirStr.cStringUsingEncoding(NSUTF8StringEncoding)
        } else {
            print("Unable to determine ROM data path; this is bad.")
            return nil
        }
    }

    func eepromPath() -> [CChar]? {
        // TODO Make this configurable
        if let userDirStr = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first {
            let eepromPathStr = userDirStr + "/tama.eep"
            return eepromPathStr.cStringUsingEncoding(NSUTF8StringEncoding)
        } else {
            print("Unable to determine EEPROM data path; this is bad.")
            return nil
        }
    }

    func renderDisplay() {
        var i = 0
        // Convert (char *) to (uint8_t *)
        // TODO Fix this type conversion nonsense
        let mirror = Mirror(reflecting: self.tama!.dram)
        for (_, value) in mirror.children {
            if let value = value as? Int {
                self.dram[i] = UInt8(value)
                i += 1
            }
        }
        self.dram.withUnsafeMutableBufferPointer { (inout ptr: UnsafeMutableBufferPointer<UInt8>) -> () in
            let lcd = self.tama!.lcd
            lcdRender(ptr.baseAddress, lcd.sizex, lcd.sizey, &self.display)
            print(self.display)
        }
    }

    func dispatchRunFrame() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            print("Emulator running for \(tamaRunCycles) cycles...")
            tamaRun(self.tamaPointer!, tamaRunCycles)
            self.renderDisplay()
            self.dispatchRunFrame()
            dispatch_async(dispatch_get_main_queue()) {
                print("This is run on the main queue, after the previous code in outer block")
            }
        }
    }

}