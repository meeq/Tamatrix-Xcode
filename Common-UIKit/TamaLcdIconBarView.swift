//
//  TamaLcdIconBarView.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 1/2/16.
//  Copyright © 2016 Christopher Bonhage. All rights reserved.
//

import UIKit

@IBDesignable
class TamaLcdIconBarView: UIView {

    let numIcons: Int = TamaIcons.count / 2
    var iconViews = [UIImageView]()
    var iconState = TamaIcons.None

    let inactiveAlpha: CGFloat = 0.4
    let activeAlpha: CGFloat = 0.9

    @IBInspectable var isBottomIconBar: Bool = false {
        didSet {
            self.updateIconImages()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initIconViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initIconViews()
    }

    func initIconViews() {
        let barWidth = CGRectGetWidth(self.frame)
        let iconSize = CGRectGetHeight(self.frame)
        let iconPadding = (barWidth - (iconSize * CGFloat(numIcons))) / (CGFloat(numIcons) + 1)
        var iconFrame = CGRectMake(iconPadding, 0, iconSize, iconSize)
        for _ in 0 ..< numIcons {
            let iconView = UIImageView(frame: iconFrame)
            iconView.contentMode = .ScaleAspectFit
            self.iconViews.append(iconView)
            self.addSubview(iconView)
            iconFrame.origin.x += iconSize + iconPadding
        }
    }

    override func layoutSubviews() {
        let barWidth = CGRectGetWidth(self.frame)
        let iconSize = CGRectGetHeight(self.frame)
        let iconPadding = (barWidth - (iconSize * CGFloat(numIcons))) / (CGFloat(numIcons) + 1)
        var iconFrame = CGRectMake(iconPadding, 0, iconSize, iconSize)
        for i in 0 ..< numIcons {
            let iconView = self.iconViews[i]
            iconView.frame = iconFrame
            iconFrame.origin.x += iconSize + iconPadding
        }
    }

    func updateIconImages() {
        let offset: Int = self.isBottomIconBar ? numIcons : 0
        for i in 0 ..< numIcons {
            let iconView = self.iconViews[i]
            iconView.image = UIImage(named: TamaIcons.names[i + offset])
            iconView.alpha = inactiveAlpha
        }
    }

}