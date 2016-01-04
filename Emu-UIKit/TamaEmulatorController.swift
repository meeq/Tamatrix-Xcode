//
//  TamaEmulatorController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

let TamaStateUpdateNotificationKey = "tamaStateUpdateNotification"

private let tamaDramSize: Int = 512
private let tamaEepromSize: Int = 65536
private let tamaClock: Int = 16000000
private let tamaFps: Int = 15
private let tamaRunCycles: Int32 = Int32(tamaClock / tamaFps) - 1
private let tamaSaveFrameInterval: UInt = 511

class TamaEmulatorController: NSObject {

    private var romPages: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>?
    private var tama: UnsafeMutablePointer<Tamagotchi>?
    private var dram = [UInt8](count: tamaDramSize, repeatedValue: 0)
    private var display = Display()
    private var state = TamaEmulatorState()
    private var frameCount: UInt = 0
    private var frameStart = NSDate()
    private var frameEnd = NSDate()

    var isPaused: Bool = false {
        didSet {
            if isPaused == oldValue {
                return
            } else if isPaused {
                saveEeprom()
                udpExit()
            } else {
                udpInit(udpServerHost()!)
            }
        }
    }
    var isAIEnabled: Bool = false

    override init() {
        super.init()
        romPages = loadRoms(romDataPath()!)
        tama = tamaInit(romPages!, eepromPath()!)
        state.emu = self
        benevolentAiInit()
        udpInit(udpServerHost()!)
    }

    deinit {
        if tama != nil {
            tamaDeinit(tama!)
        }
        if romPages != nil {
            freeRoms(romPages!)
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

    func renderDramIntoDisplay() {
        if isPaused { return }
        guard let tama = self.tama?.memory else { return }
        // TODO Fix this pointer type conversion nonsense
        // Convert (char *) Tuple to uint8_t Array
        var i = 0
        for (_, value) in Mirror(reflecting: tama.dram).children {
            dram[i] = unsafeBitCast(value as! Int8, UInt8.self)
            i += 1
        }
        // Convert uint8_t Array into (uint8_t *)
        dram.withUnsafeMutableBufferPointer { (inout ptr: UnsafeMutableBufferPointer<UInt8>) -> () in
            lcdRender(ptr.baseAddress, tama.lcd.sizex, tama.lcd.sizey, &display)
        }
    }

    func pressButton(button: TamaButton) {
        tamaPressBtn(tama!, Int32(button.rawValue))
    }

    func saveEeprom() {
        guard let tama = tama?.memory else { return }
        print("Saving EEPROM")
        let eeprom = tama.i2ceeprom.memory
        msync(eeprom.mem, tamaEepromSize, MS_SYNC)
    }

    func showFrame() {
        if isPaused { return }
        udpSendDisplay(&display)
        state.setFromDisplay(display)
        NSNotificationCenter.defaultCenter().postNotificationName(TamaStateUpdateNotificationKey, object: state)
    }

    func runFrameAsync() {
        if isPaused { return }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            self.runFrameSync()
            self.dispatchNextFrame()
        }
    }

    func runAIFrame() {
        if !isAIEnabled || isPaused { return }
        let result = Int(benevolentAiRun(&display, Int32(1000 / tamaFps)))
        if result & 1 != 0 {
            tamaPressBtn(tama!, Int32(0))
        }
        if result & 2 != 0 {
            tamaPressBtn(tama!, Int32(1))
        }
        if result & 4 != 0 {
            tamaPressBtn(tama!, Int32(2))
        }
    }

    func runFrameSync() {
        if isPaused { return }
        frameStart = NSDate()
        tamaRun(tama!, tamaRunCycles)
        renderDramIntoDisplay()
        udpTick()
        runAIFrame()
        showFrame()
        frameEnd = NSDate()
        frameCount += 1
        if frameCount & tamaSaveFrameInterval == 0 {
            saveEeprom()
        }
    }

    func dispatchNextFrame() {
        if isPaused { return }
        // TODO Revisit all of this frame scheduling
        let frameDuration = frameEnd.timeIntervalSinceDate(frameStart)
        let frameDelay: NSTimeInterval = (1.0 / Double(tamaFps)) - frameDuration
        if frameDelay > 0 {
            let timer = NSTimer(
                timeInterval: frameDelay,
                target: self,
                selector: "runFrameAsync",
                userInfo: nil,
                repeats: false)
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        } else {
            runFrameAsync()
        }
    }

}