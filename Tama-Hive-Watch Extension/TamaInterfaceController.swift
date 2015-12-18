//
//  InterfaceController.swift
//  Tama-Hive-Watch Extension
//
//  Created by Christopher Bonhage on 12/17/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import WatchKit
import Foundation


class TamaInterfaceController: WKInterfaceController {

    var tamaId: Int = 0
    var tamaPixels: String?

    @IBOutlet weak var lcd: WKInterfaceImage!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        if let contextId = context as? Int {
            self.tamaId = contextId
        }

        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    deinit {
        // Stop listening for data-change events
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (tamaPixels != nil) {
            let image = self.drawLcdImage(tamaPixels!)
            self.lcd.setImage(image)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func tamaDataDidUpdate(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            let newData = sender.object as! [Int: NSDictionary]
            if let entry = newData[self.tamaId] {
                if let pixels = entry["pixels"] as? String {
                    self.tamaPixels = pixels
                    let image = self.drawLcdImage(pixels)
                    self.lcd.setImage(image)
                }
            }
        }
    }

    func drawLcdImage(pixels: String) -> UIImage {
        let pixelSize: Int = 5
        var pixelFillSize = pixelSize
        if pixelSize > 3 {
            pixelFillSize -= 1
        }
        let imageSize = CGSizeMake(48.0 * CGFloat(pixelSize), 32.0 * CGFloat(pixelSize))

        UIGraphicsBeginImageContext(imageSize)
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!

        CGContextSetRGBFillColor(ctx, 0.937, 1.0, 0.878, 1.0)
        CGContextFillRect(ctx, CGRect(origin: CGPointZero, size: imageSize))

        var destRect = CGRect(x: 0, y: 0, width: pixelFillSize, height: pixelFillSize)
        let chars = [Character](pixels.characters)
        var i: Int = 0
        for srcY in 0..<32 {
            for srcX in 0..<48 {
                switch chars[i] {
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

        let result = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        UIGraphicsEndImageContext()
        return result
    }

}
