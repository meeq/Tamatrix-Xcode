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
        setupNibView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNibView()
    }

    var nibView: UIView!

    func setupNibView() {
        nibView = loadViewFromNib()
        nibView.frame = bounds
        nibView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(nibView)
    }

    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "TamaLcdView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }

    func setState(_ state: TamaEmulatorState) {
        // Schedule the LCD screen drawing in the background
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let lcdImage = tamaDrawLcdImage(with: state.pixels, size: self.lcdImageView.frame.size)
            // Schedule the images to be updated in the UI
            DispatchQueue.main.async {
                self.lcdImageView.image = lcdImage
                self.topIconBarView.updateIconState(state.icons)
                self.bottomIconBarView.updateIconState(state.icons)
            }
        }
    }

}
