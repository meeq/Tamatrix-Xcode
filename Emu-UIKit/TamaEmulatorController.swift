//
//  TamaEmulatorController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

let TamaStateUpdateNotificationKey = "tamaStateUpdateNotification"

private let tamaDRAMSize: Int = 512
private let tamaEEPROMSize: Int = 65536
private let tamaClock: Int = 16000000
private let tamaFPS: Int = 15
private let tamaRunCycles: Int32 = Int32(tamaClock / tamaFPS) - 1
private let tamaSaveFrameBitmask: UInt = 511

let TamaEmuSettingsIsAIEnabledKey = "isAIEnabled"
let TamaEmuSettingsIsAIEnabledDefault = false
let TamaEmuSettingsUDPServerHostKey = "udpServerHost"
let TamaEmuSettingsUDPServerHostDefault = "127.0.0.1"
let TamaEmuSettingsEEPROMFilenameKey = "eepromFilename"
let TamaEmuSettingsEEPROMFilenameDefault = "tama.eep"

func tamaEmuRegisterUserDefaults() {
    NSUserDefaults.standardUserDefaults().registerDefaults([
        TamaEmuSettingsIsAIEnabledKey: TamaEmuSettingsIsAIEnabledDefault,
        TamaEmuSettingsUDPServerHostKey: TamaEmuSettingsUDPServerHostDefault,
        TamaEmuSettingsEEPROMFilenameKey: TamaEmuSettingsEEPROMFilenameDefault
    ])
}

class TamaEmulatorController: NSObject {

    private var romPages: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>?
    private var tama: UnsafeMutablePointer<Tamagotchi>?
    private var dram = [UInt8](count: tamaDRAMSize, repeatedValue: 0)
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
                saveEEPROM()
                udpExit()
            } else {
                udpInit(udpServerHostChars()!)
            }
        }
    }

    var isAIEnabled: Bool = TamaEmuSettingsIsAIEnabledDefault {
        didSet {
            if tama != nil && isAIEnabled != oldValue {
                benevolentAiInit()
            }
        }
    }
    var udpServerHost: String = TamaEmuSettingsUDPServerHostDefault {
        didSet {
            if tama != nil && udpServerHost != oldValue {
                udpExit()
                udpInit(udpServerHostChars()!)
            }
        }
    }
    var eepromFilename: String = TamaEmuSettingsEEPROMFilenameDefault {
        didSet {
            if tama != nil && eepromFilename != oldValue {
                tamaDeinit(tama!)
                tama = tamaInit(romPages!, eepromPathChars()!)
                benevolentAiInit()
            }
        }
    }

    override init() {
        super.init()
        setupUserDefaults()
        romPages = loadRoms(romDataPathChars()!)
        tama = tamaInit(romPages!, eepromPathChars()!)
        state.emu = self
        udpInit(udpServerHostChars()!)
        benevolentAiInit()
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

    func setupUserDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        isAIEnabled = defaults.boolForKey(TamaEmuSettingsIsAIEnabledKey)
        if let settingsFilename = defaults.stringForKey(TamaEmuSettingsEEPROMFilenameKey) {
            eepromFilename = settingsFilename
        }
        if let settingsHost = defaults.stringForKey(TamaEmuSettingsUDPServerHostKey) {
            udpServerHost = settingsHost
        }
    }

    func romDataPathChars() -> [CChar]? {
        // TODO Make this configurable?
        let bundle = NSBundle.mainBundle()
        guard let romDirStr = bundle.pathForResource("rom", ofType: nil) else {
            print("Unable to determine ROM data path; this is bad.")
            return nil
        }
        print("ROM Path: \(romDirStr)")
        return romDirStr.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func eepromPathChars() -> [CChar]? {
        let dir = NSSearchPathDirectory.DocumentDirectory
        let domain = NSSearchPathDomainMask.UserDomainMask
        guard let userDirStr = NSSearchPathForDirectoriesInDomains(dir, domain, true).last else {
            print("Unable to determine EEPROM data path; this is bad.")
            return nil
        }
        let eepromPathStr = userDirStr + "/" + eepromFilename
        print("EEPROM Path: \(eepromPathStr)")
        return eepromPathStr.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func udpServerHostChars() -> [CChar]? {
        return udpServerHost.cStringUsingEncoding(NSUTF8StringEncoding)
    }

    func renderDRAMIntoDisplay() {
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
        if !isAIEnabled {
            tamaPressBtn(tama!, Int32(button.rawValue))
        }
    }

    func saveEEPROM() {
        guard let tama = tama?.memory else { return }
        print("Saving EEPROM")
        let eeprom = tama.i2ceeprom.memory
        msync(eeprom.mem, tamaEEPROMSize, MS_SYNC)
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
        switch benevolentAiRun(&display, Int32(1000 / tamaFPS)) {
        case 1: tamaPressBtn(tama!, 0)
        case 2: tamaPressBtn(tama!, 1)
        case 4: tamaPressBtn(tama!, 2)
        default: ()
        }
    }

    func runFrameSync() {
        if isPaused { return }
        frameStart = NSDate()
        tamaRun(tama!, tamaRunCycles)
        renderDRAMIntoDisplay()
        udpTick()
        runAIFrame()
        showFrame()
        frameEnd = NSDate()
        frameCount += 1
        if frameCount & tamaSaveFrameBitmask == 0 {
            saveEEPROM()
        }
    }

    func dispatchNextFrame() {
        if isPaused { return }
        let frameDuration = frameEnd.timeIntervalSinceDate(frameStart)
        let frameDelay: NSTimeInterval = (1.0 / Double(tamaFPS)) - frameDuration
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