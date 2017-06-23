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

    @IBOutlet var lcdImageView: UIImageView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareContentView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareContentView()
    }

    func prepareContentView() {
        backgroundView = UIImageView(image: tamaCellBgNormal)
        selectedBackgroundView = UIImageView(image: tamaCellBgSelected)
        lcdImageView = UIImageView(frame: frame)
        contentView.addSubview(lcdImageView)
    }

    func centerAndResizeLcdImageView() {
        // TODO Rewrite this using constraints
        let currentScreen = window?.screen ?? UIScreen.main
        let pixelScale: CGFloat = currentScreen.scale
        let width = baseLcdWidth / pixelScale
        let height = baseLcdHeight / pixelScale
        let x = (frame.width / 2) - (width / 2)
        let y = (frame.height / 2) - (height / 2)
        lcdImageView.frame = CGRect(x: x, y: y, width: width, height: height)
    }

    func redrawLcdAsync(with pixels: String) {
        guard let view: UIImageView = lcdImageView else { return }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let lcdImage = tamaDrawLcdImage(with: pixels, size: view.frame.size)
            // Schedule the image to be updated in the UI
            DispatchQueue.main.async {
                view.image = lcdImage
            }
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

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
