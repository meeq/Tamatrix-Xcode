//
//  TamaLcdImageView.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaLcdImageView: UIView {

    var pixelSize: Int = 1
    var screenData: String?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setBackgroundColor()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setBackgroundColor()
    }

    func setBackgroundColor() {
        self.backgroundColor = UIColor.init(red: 0.878, green: 0.953, blue: 0.808, alpha: 1.0)
    }

    func setTamaData(entry: NSDictionary?) {
        guard entry != nil else {
            return
        }
        self.screenData = entry!["pixels"] as? String
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        guard self.screenData != nil else {
            return
        }
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        var pixelFillSize = pixelSize
        if pixelSize > 3 {
            pixelFillSize -= 1
        }
        var destRect: CGRect = CGRect(x: 0, y: 0, width: pixelFillSize, height: pixelFillSize)
        let pixels = [Character](self.screenData!.characters)
        var i: Int = 0
        for srcY in 0..<32 {
            for srcX in 0..<48 {
                switch pixels[i] {
                case "A":
                    CGContextSetRGBFillColor(ctx, 0.937, 1.0, 0.878, 1.0)
                case "B":
                    CGContextSetRGBFillColor(ctx, 0.627, 0.690, 0.565, 1.0)
                case "C":
                    CGContextSetRGBFillColor(ctx, 0.439, 0.439, 0.345, 1.0)
                case "D":
                    CGContextSetRGBFillColor(ctx, 0.0627, 0.125, 0, 1.0)
                default:
                    break
                }
                destRect.origin = CGPoint(x: srcX * pixelSize, y: srcY * pixelSize)
                CGContextFillRect(ctx, destRect)
                i += 1
            }
        }
        
    }
    
}
