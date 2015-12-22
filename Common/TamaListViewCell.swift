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

    private var baseLcdWidth = CGFloat(tamaScreenWidth * 5)
    private var baseLcdHeight = CGFloat(tamaScreenHeight * 5)

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
        lcdImageView = TamaLcdImageView(frame: frame)
        contentView.addSubview(lcdImageView)
    }

    func centerAndResizeLcdImageView() {
        let currentScreen = self.window?.screen ?? UIScreen.mainScreen()
        let pixelScale: CGFloat = currentScreen.scale
        let width = baseLcdWidth / pixelScale
        let height = baseLcdHeight / pixelScale
        let x = (CGRectGetWidth(frame) / 2) - (width / 2)
        let y = (CGRectGetHeight(frame) / 2) - (height / 2)
        lcdImageView.frame = CGRectMake(x, y, width, height)
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