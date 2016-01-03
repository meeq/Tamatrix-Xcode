//
//  TamaLcdScreen.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

let tamaScreenWidth: Int = 48
let tamaScreenHeight: Int = 32 - 1 // The last row appears to be icon data?

private let tamaScreenBgColor = UIColor.init(red: 0.878, green: 0.953, blue: 0.808, alpha: 1)
private let tamaScreenFgColors: [Character: UIColor] = [
    "A": UIColor.init(red: 0.937, green: 1.0, blue: 0.878, alpha: 1),
    "B": UIColor.init(red: 0.627, green: 0.690, blue: 0.565, alpha: 1),
    "C": UIColor.init(red: 0.439, green: 0.439, blue: 0.345, alpha: 1),
    "D": UIColor.init(red: 0.0627, green: 0.125, blue: 0, alpha: 1)
]

private func tamaCalculateLcdFatPixelSize(size: CGSize) -> CGFloat {
    let x: CGFloat = size.width / CGFloat(tamaScreenWidth)
    let y: CGFloat = size.height / CGFloat(tamaScreenHeight)
    return min(x, y)
}

func tamaDrawLcdImage(data: String, size: CGSize) -> UIImage? {
    // Create a drawing context for the LCD
    UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
    guard let ctx: CGContextRef = UIGraphicsGetCurrentContext() else { return nil }
    tamaDrawLcdInCGContext(ctx, data: data, size: size)
    // Convert the graphics context to an image
    let result = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
    UIGraphicsEndImageContext()
    return result
}

func tamaDrawLcdInCGContext(ctx: CGContextRef, data: String, size: CGSize) {
    // Determine pixel sizes
    let pixelSize = tamaCalculateLcdFatPixelSize(size)
    // Create a tiny space between the pixels... for authenticity.
    let pixelGapSize = pixelSize * 0.1
    let pixelFillSize = pixelSize - pixelGapSize
    // Clear the background
    CGContextSetFillColorWithColor(ctx, tamaScreenBgColor.CGColor)
    CGContextFillRect(ctx, CGRect(origin: CGPointZero, size: size))
    // Iterate through the source pixels as characters and paint them as fat pixels
    let pixelChars = [Character](data.characters)
    var i: Int = 0
    for srcY in 0..<tamaScreenHeight {
        for srcX in 0..<tamaScreenWidth {
            // Look up the foreground color from 2-bit pixel
            let pixelColor = tamaScreenFgColors[pixelChars[i]] ?? tamaScreenBgColor
            CGContextSetFillColorWithColor(ctx, pixelColor.CGColor)
            let destX = CGFloat(srcX) * pixelSize
            let destY = CGFloat(srcY) * pixelSize
            let destW = pixelFillSize
            let destH = pixelFillSize
            let destRect = CGRectMake(destX, destY, destW, destH)
            CGContextFillRect(ctx, destRect)
            i += 1
        }
    }
}