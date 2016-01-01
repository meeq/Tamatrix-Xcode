//
//  TamaEmuViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaEmuViewController: UIViewController {

    private var tama: TamaEmulatorState?

    @IBOutlet weak var lcdImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaStateDidUpdate:",
            name: TamaStateUpdateNotificationKey,
            object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func tamaStateDidUpdate(sender: AnyObject) {
        self.tama = sender.object as? TamaEmulatorState
        guard let pixels = self.tama?.pixels else {
            return
        }
        self.redrawLcdAsync(pixels)
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

    @IBAction func userDidPressButton(sender: UIButton) {
        if let text = sender.titleLabel?.text {
            self.tama?.pressButton(TamaButton.fromString(text))
        }
    }

}

