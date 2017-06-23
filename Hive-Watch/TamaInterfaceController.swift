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
    private var lcdSize: CGSize = CGSize.zero

    @IBOutlet weak var lcd: WKInterfaceImage!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Set properties from context
        if let tamaModel = context as? TamaModel {
            tamaId = tamaModel.id
            tamaPixels = tamaModel.pixels
        }
        determineLcdSize()
        // Listen for data-change events
        NotificationCenter.default.addObserver(self,
            selector: #selector(TamaInterfaceController.tamaDataDidUpdate(_:)),
            name: NSNotification.Name(rawValue: TamaDataUpdateNotificationKey),
            object: nil)
    }

    deinit {
        // Stop listening for data-change events
        NotificationCenter.default.removeObserver(self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        isActive = true
        redrawLcdSync()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        isActive = false
    }

    func determineLcdSize() {
        // Determine image size
        let aspectRatio = CGFloat(tamaScreenWidth) / CGFloat(tamaScreenHeight)
        let width = WKInterfaceDevice.current().screenBounds.width
        let height = width / aspectRatio
        lcdSize = CGSize(width: width, height: height)
    }

    func redrawLcdSync() {
        // Only draw if the view is visible and we have pixel data
        if !isActive || tamaPixels == nil {
            return
        }
        lcd.setImage(tamaDrawLcdImage(with: tamaPixels!, size: lcdSize))
    }

    func redrawLcdAsync() {
        // Only draw if the view is visible and we have pixel data
        if !isActive || tamaPixels == nil {
            return
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let lcdImage = tamaDrawLcdImage(with: self.tamaPixels!, size: self.lcdSize)
            // Schedule the image to be updated in the UI
            DispatchQueue.main.async {
                self.lcd.setImage(lcdImage)
            }
        }
    }

    func tamaDataDidUpdate(_ sender: AnyObject) {
        let newData = sender.object as! [Int: TamaModel]
        // Extract the pixel data from the fetched dump
        if let tamaModel = newData[tamaId] {
            tamaPixels = tamaModel.pixels
            redrawLcdAsync()
        }
    }

}
