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

    var romData: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>?
    var tamaPointer: UnsafeMutablePointer<Tamagotchi>?
    var tama: Tamagotchi?
    var dram = [UInt8](count: tamaDramSize, repeatedValue: 0)
    var display = Display()
    var frameCount: UInt = 0
    var isAIEnabled: Bool = true

    override init() {
        super.init()
        self.romData = loadRoms(self.romDataPath()!)
        self.tamaPointer = tamaInit(self.romData!, self.eepromPath()!)
        self.tama = self.tamaPointer!.memory
        benevolentAiInit()
        udpInit(self.udpServerHost()!)
    }

    deinit {
        if self.tamaPointer != nil {
            tamaDeinit(self.tamaPointer!)
        }
        if self.romData != nil {
            freeRoms(self.romData!)
        }
        udpExit()
    }

    func romDataPath() -> [CChar]? {
        // TODO Make this configurable
        let bundle = NSBundle.mainBundle()
        guard let romDirStr = bundle.pathForResource("rom", ofType: nil) else {
            print("Unable to determine ROM data path; this is bad.")
            return nil
        }
        print("ROM Path: \(romDirStr)")
        return romDirStr.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func eepromPath() -> [CChar]? {
        // TODO Make this configurable
        let dir = NSSearchPathDirectory.DocumentDirectory
        let domain = NSSearchPathDomainMask.UserDomainMask
        guard let userDirStr = NSSearchPathForDirectoriesInDomains(dir, domain, true).last else {
            print("Unable to determine EEPROM data path; this is bad.")
            return nil
        }
        let eepromPathStr = userDirStr + "/tama.eep"
        print("EEPROM Path: \(eepromPathStr)")
        return eepromPathStr.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func udpServerHost() -> [CChar]? {
        // TODO Make this configurable
        let hostStr: String = "127.0.0.1"
        return hostStr.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func renderDisplay() {
        // TODO Fix this pointer type conversion nonsense
        // Convert (char *) Tuple to uint8_t Array
        var i = 0
        for (_, value) in Mirror(reflecting: self.tama!.dram).children {
            self.dram[i] = UInt8(value as! Int8)
            i += 1
        }
        // Convert uint8_t Array into (uint8_t *)
        self.dram.withUnsafeMutableBufferPointer { (inout ptr: UnsafeMutableBufferPointer<UInt8>) -> () in
            let lcd = self.tama!.lcd
            lcdRender(ptr.baseAddress, lcd.sizex, lcd.sizey, &self.display)
        }
    }

    func runFrameAsync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            var frameStartTime = timespec()
            clock_gettime(CLOCK_MONOTONIC, &frameStartTime)
            tamaRun(self.tamaPointer!, tamaRunCycles - 1)
            self.renderDisplay()
            udpTick()
            if (self.frameCount & 15) == 0 {
                dispatch_async(dispatch_get_main_queue()) {
                    lcdShow(&self.display)
                    udpSendDisplay(&self.display)
                    tamaDumpHw(self.tama!.cpu)
                    benevolentAiDump()
                }
            }
            var frameEndTime = timespec()
            clock_gettime(CLOCK_MONOTONIC, &frameEndTime)
            self.frameCount += 1
            self.dispatchNextFrame(frameStartTime, frameEndTime: frameEndTime)
        }
    }

    func dispatchNextFrame(frameStartTime: timespec, frameEndTime: timespec) {
        var frameDuration: Double // In Microseconds
        frameDuration = Double(frameEndTime.tv_nsec - frameStartTime.tv_nsec) / 1000.0
        frameDuration += Double(frameEndTime.tv_sec - frameStartTime.tv_sec) * 1000000.0
        let frameDelay: Double = (1000000.0 / Double(tamaFps)) - frameDuration
        if frameDelay > 0 {
            let timer = NSTimer(
                timeInterval: NSTimeInterval(frameDelay / 1000000.0),
                target: self,
                selector: "runFrameAsync",
                userInfo: nil,
                repeats: false)
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        } else {
            self.runFrameAsync()
        }
    }

}