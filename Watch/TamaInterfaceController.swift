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

    private var tamaId: Int = 0
    private var tamaPixels: String?
    private var isActive: Bool = false
    private var lcdSize: CGSize = CGSizeZero

    @IBOutlet weak var lcd: WKInterfaceImage!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Set properties from context
        if let contextDict = context as? NSDictionary {
            self.tamaId = contextDict["id"] as! Int
            self.tamaPixels = contextDict["pixels"] as? String
        }
        determineLcdSize()
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
            // Only draw if the view is visible
            if self.isActive {
                let lcdImage = self.drawLcdImage(pixels)
                // Schedule the image to be updated in the UI
                dispatch_async(dispatch_get_main_queue()) {
                    self.lcd.setImage(lcdImage)
                }
            }
        }
    }

    func determineLcdSize() {
        // Determine image size
        let aspectRatio = CGFloat(tamaScreenWidth) / CGFloat(tamaScreenHeight)
        let width = CGRectGetWidth(WKInterfaceDevice.currentDevice().screenBounds)
        let height = width / aspectRatio
        lcdSize = CGSizeMake(width, height)
    }

    func drawLcdImage(pixels: String) -> UIImage {
        // Create a drawing context for the LCD
        UIGraphicsBeginImageContextWithOptions(lcdSize, true, 0.0)
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
        tamaDrawLcdInCGContext(ctx, data: pixels, size: lcdSize)
        // Convert the graphics context to an image
        let result = UIImage(CGImage: CGBitmapContextCreateImage(ctx)!)
        UIGraphicsEndImageContext()
        return result
    }

}
