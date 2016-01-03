//
//  TamaEmulatorState.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 1/1/16.
//  Copyright © 2016 Christopher Bonhage. All rights reserved.
//

import Foundation

enum TamaButton: Int {
    case None = -1
    case A = 0
    case B = 1
    case C = 2

    static func fromString(string: String) -> TamaButton {
        switch string {
            case "A": return .A
            case "B": return .B
            case "C": return .C
            default : return .None
        }
    }
}

struct TamaIcons: OptionSetType {
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

class TamaEmulatorState: NSObject {

    var pixels: String?
    var icons = TamaIcons.None
    weak var emu: TamaEmulatorController?

    func setFromDisplay(display: Display) {
        let pixelCharMap: [Character] = ["A", "B", "C", "D"]
        var charAcc = [Character]()
        // Extract the pixels from (char **) using smoke and (mostly) mirrors
        for (_, row) in Mirror(reflecting: display.p).children {
            for (_, pixel) in Mirror(reflecting: row).children {
                charAcc.append(pixelCharMap[Int(pixel as! Int8) & 3])
            }
        }
        self.pixels = String(charAcc)
        self.icons = TamaIcons(rawValue: Int(display.icons))
    }

    func pressButton(button: TamaButton) {
        if button != .None {
            self.emu?.pressButton(button)
        }
    }
    
}
