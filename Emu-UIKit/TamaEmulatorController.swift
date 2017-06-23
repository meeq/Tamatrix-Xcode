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
    UserDefaults.standard.register(defaults: [
        TamaEmuSettingsIsAIEnabledKey: TamaEmuSettingsIsAIEnabledDefault,
        TamaEmuSettingsUDPServerHostKey: TamaEmuSettingsUDPServerHostDefault,
        TamaEmuSettingsEEPROMFilenameKey: TamaEmuSettingsEEPROMFilenameDefault
    ])
}

class TamaEmulatorController: NSObject {

    private var romPages: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?
    private var tama: UnsafeMutablePointer<Tamagotchi>?
    private var dram = [UInt8](repeating: 0, count: tamaDRAMSize)
    private var display = Display()
    private var state = TamaEmulatorState()
    private var frameCount: UInt = 0
    private var frameStart = Date()
    private var frameEnd = Date()

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
        loadUserDefaults()
        // Setup emulator
        romPages = loadRoms(romDataPathChars()!)
        tama = tamaInit(romPages!, eepromPathChars()!)
        state.emu = self
        udpInit(udpServerHostChars()!)
        benevolentAiInit()
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(TamaEmulatorController.userDefaultsChanged(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil)

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

    func loadUserDefaults() {
        let defaults = UserDefaults.standard
        isAIEnabled = defaults.bool(forKey: TamaEmuSettingsIsAIEnabledKey)
        if let settingsFilename = defaults.string(forKey: TamaEmuSettingsEEPROMFilenameKey) {
            eepromFilename = settingsFilename
        }
        if let settingsHost = defaults.string(forKey: TamaEmuSettingsUDPServerHostKey) {
            udpServerHost = settingsHost
        }
    }

    func userDefaultsChanged(_ notification: Notification) {
        loadUserDefaults()
    }

    func romDataPathChars() -> [CChar]? {
        // TODO Make this configurable?
        let bundle = Bundle.main
        guard let romDirStr = bundle.path(forResource: "rom", ofType: nil) else {
            print("Unable to determine ROM data path; this is bad.")
            return nil
        }
        print("ROM Path: \(romDirStr)")
        return romDirStr.cString(using: String.Encoding.utf8)
    }

    func eepromPathChars() -> [CChar]? {
        let dir = FileManager.SearchPathDirectory.documentDirectory
        let domain = FileManager.SearchPathDomainMask.userDomainMask
        guard let userDirStr = NSSearchPathForDirectoriesInDomains(dir, domain, true).last else {
            print("Unable to determine EEPROM data path; this is bad.")
            return nil
        }
        let eepromPathStr = userDirStr + "/" + eepromFilename
        print("EEPROM Path: \(eepromPathStr)")
        return eepromPathStr.cString(using: String.Encoding.utf8)
    }

    func udpServerHostChars() -> [CChar]? {
        return udpServerHost.cString(using: String.Encoding.utf8)
    }

    func renderDRAMIntoDisplay() {
        if isPaused { return }
        guard let tama = self.tama?.pointee else { return }
        // TODO Fix this pointer type conversion nonsense
        // Convert (char *) Tuple to uint8_t Array
        var i = 0
        for (_, value) in Mirror(reflecting: tama.dram).children {
            dram[i] = UInt8(bitPattern: value as! Int8)
            i += 1
        }
        // Convert uint8_t Array into (uint8_t *)
        dram.withUnsafeMutableBufferPointer { (ptr: inout UnsafeMutableBufferPointer<UInt8>) -> () in
            lcdRender(ptr.baseAddress, tama.lcd.sizex, tama.lcd.sizey, &display)
        }
    }

    func pressButton(_ button: TamaButton) {
        if !isAIEnabled {
            tamaPressBtn(tama!, Int32(button.rawValue))
        }
    }

    func saveEEPROM() {
        guard let tama = tama?.pointee else { return }
        print("Saving EEPROM")
        let eeprom = tama.i2ceeprom.pointee
        msync(eeprom.mem, tamaEEPROMSize, MS_SYNC)
    }

    func showFrame() {
        if isPaused { return }
        udpSendDisplay(&display)
        state.setFromDisplay(display)
        NotificationCenter.default.post(name: Notification.Name(rawValue: TamaStateUpdateNotificationKey), object: state)
    }

    func runFrameAsync() {
        if isPaused { return }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
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
        default: break
        }
    }

    func runFrameSync() {
        if isPaused { return }
        frameStart = Date()
        tamaRun(tama!, tamaRunCycles)
        renderDRAMIntoDisplay()
        udpTick()
        runAIFrame()
        showFrame()
        frameEnd = Date()
        frameCount += 1
        if frameCount & tamaSaveFrameBitmask == 0 {
            saveEEPROM()
        }
    }

    func dispatchNextFrame() {
        if isPaused { return }
        let frameDuration = frameEnd.timeIntervalSince(frameStart)
        let frameDelay: TimeInterval = (1.0 / Double(tamaFPS)) - frameDuration
        if frameDelay > 0 {
            let timer = Timer(
                timeInterval: frameDelay,
                target: self,
                selector: #selector(TamaEmulatorController.runFrameAsync),
                userInfo: nil,
                repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        } else {
            runFrameAsync()
        }
    }

}
