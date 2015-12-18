//
//  TamaListViewCell.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListViewCell: UICollectionViewCell {

    private let tamaCellBgNormal = UIImage(named: "hexagon.png")
    private let tamaCellBgFocused = UIImage(named: "hexagon-invert.png")
    private let tamaCellBgSelected = UIImage(named: "hexagon-invert-dark.png")

    @IBOutlet var lcdImageView: TamaLcdImageView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.prepareContentView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.prepareContentView()
    }

    func prepareContentView() {
        backgroundView = UIImageView(image: tamaCellBgNormal)
        selectedBackgroundView = UIImageView(image: tamaCellBgSelected)

        // TODO Remove hard-coded LCD frame size; use autolayout?
        let lcdFrame = CGRect(x: 15, y: 85, width: 240, height: 160)
        lcdImageView = TamaLcdImageView(frame: lcdFrame)
        contentView.addSubview(lcdImageView)
    }

    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocusInContext(context, withAnimationCoordinator: coordinator)

        coordinator.addCoordinatedAnimations({
                let backgroundView = self.backgroundView as! UIImageView
                if self == context.nextFocusedView {
                    backgroundView.image = self.tamaCellBgFocused
                } else {
                    backgroundView.image = self.tamaCellBgNormal
                }
                backgroundView.setNeedsDisplay()
            },
            completion: nil
        )
    }

}