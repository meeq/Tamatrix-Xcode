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
    @IBOutlet weak var lcdTopIconBar: TamaLcdIconBarView!
    @IBOutlet weak var lcdBottomIconBar: TamaLcdIconBarView!

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
        guard let tama = sender.object as? TamaEmulatorState else { return }
        self.tama = tama
        if let pixels = tama.pixels {
            self.redrawLcdAsync(pixels, icons: tama.icons)
        }
    }

    func redrawLcdAsync(pixels: String, icons: TamaIcons) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let lcdImage = tamaDrawLcdImage(pixels, size: self.lcdImageView.frame.size)
            // Schedule the image to be updated in the UI
            dispatch_async(dispatch_get_main_queue()) {
                self.lcdImageView.image = lcdImage
                self.lcdTopIconBar.updateIconState(icons)
                self.lcdBottomIconBar.updateIconState(icons)
            }
        }
    }

    @IBAction func userDidPressButton(sender: UIButton) {
        if let text = sender.titleLabel?.text {
            self.tama?.pressButton(TamaButton.fromString(text))
        }
    }

}

