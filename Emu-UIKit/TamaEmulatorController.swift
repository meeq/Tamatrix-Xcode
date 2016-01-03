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

    private var romData: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>?
    private var tama: UnsafeMutablePointer<Tamagotchi>?
    private var dram = [UInt8](count: tamaDramSize, repeatedValue: 0)
    private var display = Display()
    private var state = TamaEmulatorState()
    private var frameCount: UInt = 0
    private var frameStart = NSDate()
    private var frameEnd = NSDate()

    var isPaused: Bool = false
    var isAIEnabled: Bool = true

    override init() {
        super.init()
        self.romData = loadRoms(self.romDataPath()!)
        self.tama = tamaInit(self.romData!, self.eepromPath()!)
        self.state.emu = self
        benevolentAiInit()
        udpInit(self.udpServerHost()!)
    }

    deinit {
        if self.tama != nil {
            tamaDeinit(self.tama!)
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

    func renderDramIntoDisplay() {
        let tama = self.tama!.memory
        // TODO Fix this pointer type conversion nonsense
        // Convert (char *) Tuple to uint8_t Array
        var i = 0
        for (_, value) in Mirror(reflecting: tama.dram).children {
            self.dram[i] = unsafeBitCast(value as! Int8, UInt8.self)
            i += 1
        }
        // Convert uint8_t Array into (uint8_t *)
        self.dram.withUnsafeMutableBufferPointer { (inout ptr: UnsafeMutableBufferPointer<UInt8>) -> () in
            lcdRender(ptr.baseAddress, tama.lcd.sizex, tama.lcd.sizey, &self.display)
        }
    }

    func pressButton(button: TamaButton) {
        tamaPressBtn(self.tama!, Int32(button.rawValue))
    }

    func saveEeprom() {
        print("Saving EEPROM")
        guard let tama = self.tama?.memory else { return }
        let eeprom = tama.i2ceeprom.memory
        // For some strange reason, EEPROM changes don't sync unless we munmap
        // (This could just be the simulator lying to me, though)
        msync(eeprom.mem, tamaEepromSize, MS_SYNC)
        munmap(eeprom.mem, tamaEepromSize)
        mmap(nil, tamaEepromSize, PROT_READ | PROT_WRITE, MAP_SHARED, eeprom.fd, 0)
    }

    func showFrame() {
        udpSendDisplay(&self.display)
        self.state.setFromDisplay(self.display)
        NSNotificationCenter.defaultCenter().postNotificationName(TamaStateUpdateNotificationKey, object: self.state)
    }

    func runFrameAsync() {
        if self.isPaused { return }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            self.runFrameSync()
            self.dispatchNextFrame()
        }
    }

    func runFrameSync() {
        if self.isPaused { return }
        self.frameStart = NSDate()
        tamaRun(self.tama!, tamaRunCycles)
        self.renderDramIntoDisplay()
        udpTick()
        self.showFrame()
        self.frameEnd = NSDate()
        self.frameCount += 1
        if self.frameCount & tamaSaveFrameInterval == 0 {
            self.saveEeprom()
        }
    }

    func dispatchNextFrame() {
        if self.isPaused { return }
        // TODO Revisit all of this frame scheduling
        let frameDuration = self.frameEnd.timeIntervalSinceDate(self.frameStart)
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
            self.runFrameAsync()
        }
    }

}