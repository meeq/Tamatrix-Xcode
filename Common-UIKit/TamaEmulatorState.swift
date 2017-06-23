//
//  TamaEmulatorState.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 1/1/16.
//  Copyright © 2016 Christopher Bonhage. All rights reserved.
//

import Foundation

enum TamaButton: Int {
    case none = -1
    case a = 0
    case b = 1
    case c = 2

    static func fromString(_ string: String) -> TamaButton {
        switch string {
            case "A": return .a
            case "B": return .b
            case "C": return .c
            default : return .none
        }
    }
}

struct TamaIcons: OptionSet {
    let rawValue: Int

    static let None         = TamaIcons(rawValue: 0)
    static let Info         = TamaIcons(rawValue: 1 << 0)
    static let Food         = TamaIcons(rawValue: 1 << 1)
    static let Toilet       = TamaIcons(rawValue: 1 << 2)
    static let Door         = TamaIcons(rawValue: 1 << 3)
    static let Figure       = TamaIcons(rawValue: 1 << 4)
    static let Training     = TamaIcons(rawValue: 1 << 5)
    static let Medicine     = TamaIcons(rawValue: 1 << 6)
    static let IR           = TamaIcons(rawValue: 1 << 7)
    static let Album        = TamaIcons(rawValue: 1 << 8)
    static let Attention    = TamaIcons(rawValue: 1 << 9)

    static func fromIndex(_ index: Int) -> TamaIcons {
        return TamaIcons(rawValue: 1 << index)
    }

    static let count = 10
    static let names = [
        "Info",
        "Food",
        "Toilet",
        "Door",
        "Figure",
        "Training",
        "Medicine",
        "IR",
        "Album",
        "Attention"
    ]
}

class TamaEmulatorState: NSObject {

    static let pixelCount = tamaScreenWidth * tamaScreenHeight

    var pixels = String([Character](repeating: "A", count: pixelCount))
    var icons = TamaIcons.None

    weak var emu: TamaEmulatorController?

    func setFromDisplay(_ display: Display) {
        let pixelCharMap: [Character] = ["A", "B", "C", "D"]
        var charAcc = [Character]()
        // Extract the pixels from (char **) using smoke and (mostly) mirrors
        for (_, row) in Mirror(reflecting: display.p).children {
            for (_, pixel) in Mirror(reflecting: row).children {
                charAcc.append(pixelCharMap[Int(pixel as! Int8) & 3])
            }
        }
        pixels = String(charAcc)
        icons = TamaIcons(rawValue: Int(display.icons))
    }

    func pressButton(_ button: TamaButton) {
        if button != .none {
            emu?.pressButton(button)
        }
    }
    
}
