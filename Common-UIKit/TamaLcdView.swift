//
//  TamaLcdView.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 1/3/16.
//  Copyright © 2016 Christopher Bonhage. All rights reserved.
//

import UIKit

@IBDesignable
class TamaLcdView: UIView {

    @IBOutlet weak var lcdImageView: UIImageView!
    @IBOutlet weak var topIconBarView: TamaLcdIconBarView!
    @IBOutlet weak var bottomIconBarView: TamaLcdIconBarView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initNibView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initNibView()
    }

    func initNibView() {
        let nib = NSBundle.mainBundle().loadNibNamed("TamaLcdView", owner: self, options: nil)
        if let view = nib.first as? UIView {
            self.addSubview(view)
            view.frame = self.bounds
        }
    }

    func setState(state: TamaEmulatorState) {
        // Schedule the LCD screen drawing in the background
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let lcdImage = tamaDrawLcdImage(state.pixels, size: self.lcdImageView.frame.size)
            // Schedule the images to be updated in the UI
            dispatch_async(dispatch_get_main_queue()) {
                self.lcdImageView.image = lcdImage
                self.topIconBarView.updateIconState(state.icons)
                self.bottomIconBarView.updateIconState(state.icons)
            }
        }
    }

}
