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

    let inactiveAlpha: CGFloat = 0.3
    let activeAlpha: CGFloat = 1.0

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
        for _ in 0 ..< numIcons {
            let iconView = UIImageView(frame: CGRectZero)
            iconView.contentMode = .ScaleAspectFit
            self.iconViews.append(iconView)
            self.addSubview(iconView)
        }
    }

    override func layoutSubviews() {
        let barWidth = CGRectGetWidth(self.frame)
        let barHeight = CGRectGetHeight(self.frame)
        let iconSize = barHeight * 0.75
        let iconPadding = (barWidth - (iconSize * CGFloat(numIcons))) / (CGFloat(numIcons))
        var iconFrame = CGRectMake(iconPadding / 2, (barHeight - iconSize) / 2, iconSize, iconSize)
        for i in 0 ..< numIcons {
            let iconView = self.iconViews[i]
            iconView.frame = iconFrame
            iconFrame.origin.x += iconSize + iconPadding
        }
    }

    func updateIconImages() {
        let offset = self.isBottomIconBar ? numIcons : 0
        for i in 0 ..< numIcons {
            let iconView = self.iconViews[i]
            iconView.image = UIImage(named: TamaIcons.names[i + offset])
            iconView.alpha = inactiveAlpha
        }
    }

    func updateIconState(icons: TamaIcons) {
        self.iconState = icons
        let offset = self.isBottomIconBar ? numIcons : 0
        for i in 0 ..< numIcons {
            let iconView = self.iconViews[i]
            let testIcon = TamaIcons.fromIndex(i + offset)
            iconView.alpha = self.iconState.contains(testIcon) ? activeAlpha : inactiveAlpha
        }
    }

}