//
//  TamaInterfaceController.swift
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
    var isActive: Bool = false

    @IBOutlet weak var lcd: WKInterfaceImage!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Set properties from context
        if let contextId = context as? Int {
            self.tamaId = contextId
        }
        if let contextDict = context as? NSDictionary {
            self.tamaId = contextDict["id"] as! Int
            self.tamaPixels = contextDict["pixels"] as? String
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
        self.isActive = true
        // Draw the LCD on activation if we have pixel data
        if (tamaPixels != nil) {
            let image = self.drawLcdImage(tamaPixels!)
            self.lcd.setImage(image)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.isActive = false
    }

    func tamaDataDidUpdate(sender: AnyObject) {
        let newData = sender.object as! [Int: NSDictionary]
        // Extract the pixel data from the fetched dump
        if let pixels = newData[self.tamaId]?["pixels"] as? String {
            self.tamaPixels = pixels
            if self.isActive {
                let lcdImage = self.drawLcdImage(pixels)
                // Schedule the image to be updated in the UI
                dispatch_async(dispatch_get_main_queue()) {
                    self.lcd.setImage(lcdImage)
                }
            }
        }
    }

    func drawLcdImage(pixels: String) -> UIImage {
        // Create a drawing context for the LCD
        let imageSize = CGSizeMake(240, 160)
        UIGraphicsBeginImageContext(imageSize)
        tamaDrawLcdInCurrentCGContext(pixels, size: imageSize)

        // Convert the graphics context to an image
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        let result = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        UIGraphicsEndImageContext()
        return result
    }

}
