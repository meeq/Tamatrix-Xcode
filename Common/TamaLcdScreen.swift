//
//  TamaLcdScreen.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

private let tamaScreenWidth: Int = 48
private let tamaScreenHeight: Int = 32

private let tamaScreenMinGapPixelSize: Int = 5
private let tamaScreenBgColor = UIColor.init(red: 0.878, green: 0.953, blue: 0.808, alpha: 1.0)
private let tamaScreenFgColors: [Character: UIColor] = [
    "A": UIColor.init(red: 0.937, green: 1.0, blue: 0.878, alpha: 1.0),
    "B": UIColor.init(red: 0.627, green: 0.690, blue: 0.565, alpha: 1.0),
    "C": UIColor.init(red: 0.439, green: 0.439, blue: 0.345, alpha: 1.0),
    "D": UIColor.init(red: 0.0627, green: 0.125, blue: 0, alpha: 1.0)
]

private func tamaCalculateLcdPixelSize(size: CGSize) -> Int {
    let x: CGFloat = size.width / CGFloat(tamaScreenWidth)
    let y: CGFloat = size.height / CGFloat(tamaScreenHeight)
    return Int(min(x, y))
}

func tamaDrawLcdInCurrentCGContext(data: String, size: CGSize) {
    let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
    // Determine pixel sizes
    let pixelSize = tamaCalculateLcdPixelSize(size)
    var pixelFillSize = pixelSize
    if pixelSize >= tamaScreenMinGapPixelSize {
        pixelFillSize -= 1
    }
    // Clear the background
    CGContextSetFillColorWithColor(ctx, tamaScreenBgColor.CGColor)
    CGContextFillRect(ctx, CGRect(origin: CGPointZero, size: size))
    // Iterate through the source pixels as characters and paint them as fat pixels
    let pixelChars = [Character](data.characters)
    var destRect: CGRect = CGRect(x: 0, y: 0, width: pixelFillSize, height: pixelFillSize)
    var i: Int = 0
    for srcY in 0..<tamaScreenHeight {
        for srcX in 0..<tamaScreenWidth {
            // Look up the foreground color from 2-bit pixel
            if let cgColor = tamaScreenFgColors[pixelChars[i]]?.CGColor {
                CGContextSetFillColorWithColor(ctx, cgColor)
            }
            destRect.origin = CGPoint(x: srcX * pixelSize, y: srcY * pixelSize)
            CGContextFillRect(ctx, destRect)
            i += 1
        }
    }
}