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
        self.setupNibView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupNibView()
    }

    var nibView: UIView!

    func setupNibView() {
        nibView = loadViewFromNib()
        nibView.frame = bounds
        nibView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        addSubview(nibView)
    }

    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "TamaLcdView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil).first as! UIView
        return view
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
