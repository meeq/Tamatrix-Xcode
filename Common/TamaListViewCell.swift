//
//  TamaListViewCell.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

let tamaCellBgNormal = UIImage(named: "hexagon.png")
let tamaCellBgFocused = UIImage(named: "hexagon-invert.png")
let tamaCellBgSelected = UIImage(named: "hexagon-invert-dark.png")

class TamaListViewCell: UICollectionViewCell {

    @IBOutlet var lcdImageView: TamaLcdImageView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initContentView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initContentView()
    }

    func initContentView() {
        backgroundView = UIImageView(image: tamaCellBgNormal)
        selectedBackgroundView = UIImageView(image: tamaCellBgSelected)

        let lcdFrame = CGRect(x: 15, y: 85, width: 240, height: 160)
        lcdImageView = TamaLcdImageView(frame: lcdFrame)
        contentView.addSubview(lcdImageView)
    }

    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocusInContext(context, withAnimationCoordinator: coordinator)

        coordinator.addCoordinatedAnimations({
                let backgroundView = self.backgroundView as! UIImageView
                if self == context.nextFocusedView {
                    backgroundView.image = tamaCellBgFocused
                } else {
                    backgroundView.image = tamaCellBgNormal
                }
                backgroundView.setNeedsDisplay()
            },
            completion: nil
        )
    }

}