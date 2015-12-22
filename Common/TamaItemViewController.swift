//
//  TamaItemViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaItemViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var lcdImageView: UIImageView!

    var tamaId: Int = 0

    func tamaDataDidUpdate(sender: AnyObject) {
        let tamaData = sender.object as! [Int: NSDictionary]
        if let pixels = tamaData[self.tamaId]?["pixels"] as? String {
            self.redrawLcdAsync(pixels)
        }
    }

    func redrawLcdAsync(pixels: String) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let lcdImage = tamaDrawLcdImage(pixels, size: self.lcdImageView.frame.size)
            // Schedule the image to be updated in the UI
            dispatch_async(dispatch_get_main_queue()) {
                self.lcdImageView.image = lcdImage
            }
        }
    }

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Register for data update notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    deinit {
        // Stop listening for data updates
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

