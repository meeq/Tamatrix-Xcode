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

private func tamaCalculateLcdFatPixelSize(for contextSize: CGSize) -> CGFloat {
    let x: CGFloat = contextSize.width / CGFloat(tamaScreenWidth)
    let y: CGFloat = contextSize.height / CGFloat(tamaScreenHeight)
    return min(x, y)
}

func tamaDrawLcdImage(with data: String, size: CGSize) -> UIImage? {
    // Create a drawing context for the LCD
    UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
    guard let context: CGContext = UIGraphicsGetCurrentContext() else { return nil }
    tamaDrawLcd(in: context, data: data, size: size)
    // Convert the graphics context to an image
    let result = UIImage(cgImage: context.makeImage()!)
    UIGraphicsEndImageContext()
    return result
}

func tamaDrawLcd(in context: CGContext, data: String, size: CGSize) {
    // Determine pixel sizes
    let pixelSize = tamaCalculateLcdFatPixelSize(for: size)
    // Create a tiny space between the pixels... for authenticity.
    let pixelGapSize = pixelSize * 0.2
    let pixelFillSize = pixelSize - pixelGapSize
    // Clear the background
    context.setFillColor(tamaScreenBgColor.cgColor)
    context.fill(CGRect(origin: CGPoint.zero, size: size))
    // Iterate through the source pixels as characters and paint them as fat pixels
    let pixelChars = [Character](data.characters)
    var i: Int = 0
    for srcY in 0..<tamaScreenHeight {
        for srcX in 0..<tamaScreenWidth {
            // Look up the foreground color from 2-bit pixel
            let pixelColor = tamaScreenFgColors[pixelChars[i]] ?? tamaScreenBgColor
            context.setFillColor(pixelColor.cgColor)
            let destX = CGFloat(srcX) * pixelSize
            let destY = CGFloat(srcY) * pixelSize
            let destW = pixelFillSize
            let destH = pixelFillSize
            let destRect = CGRect(x: destX, y: destY, width: destW, height: destH)
            context.fill(destRect)
            i += 1
        }
    }
}
