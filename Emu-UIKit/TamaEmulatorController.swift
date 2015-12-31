//
//  TamaEmulatorController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import Foundation

class TamaEmulatorController: NSObject {

    var tama: Tamagotchi?
    var tamaPointer: UnsafeMutablePointer<Tamagotchi>?
    var microSecs: UInt = 0
    var frameCount: UInt = 0
    var isAIEnabled: Bool = true

    override init() {
        // Load roms
        let bundle = NSBundle.mainBundle()
        let romDirStr = bundle.pathForResource("rom", ofType: nil)
        let romDirChars = romDirStr?.cStringUsingEncoding(NSUTF8StringEncoding)
        let romData = loadRoms(romDirChars!)
        let userDirStr = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let eepromPathStr = userDirStr + "/tama.eep"
        let eepromPathChars = eepromPathStr.cStringUsingEncoding(NSUTF8StringEncoding)
        self.tamaPointer = tamaInit(romData, eepromPathChars!)
        self.tama = self.tamaPointer!.memory
        // Initialize tama
        super.init()
    }

}