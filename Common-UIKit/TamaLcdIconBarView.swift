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

    let inactiveAlpha: CGFloat = 0.3
    let activeAlpha: CGFloat = 1.0

    @IBInspectable var isBottomIconBar: Bool = false {
        didSet {
            updateIconImages()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initIconViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initIconViews()
    }

    func initIconViews() {
        for _ in 0 ..< numIcons {
            let iconView = UIImageView(frame: CGRectZero)
            iconView.contentMode = .ScaleAspectFit
            iconViews.append(iconView)
            addSubview(iconView)
        }
    }

    override func layoutSubviews() {
        let barWidth = CGRectGetWidth(frame)
        let barHeight = CGRectGetHeight(frame)
        let iconSize = barHeight * 0.75
        let iconPadding = (barWidth - (iconSize * CGFloat(numIcons))) / (CGFloat(numIcons))
        var iconFrame = CGRectMake(iconPadding / 2, (barHeight - iconSize) / 2, iconSize, iconSize)
        for i in 0 ..< numIcons {
            let iconView = iconViews[i]
            iconView.frame = iconFrame
            iconFrame.origin.x += iconSize + iconPadding
        }
    }

    func updateIconImages() {
        let offset = isBottomIconBar ? numIcons : 0
        for i in 0 ..< numIcons {
            let iconView = iconViews[i]
            iconView.image = UIImage(named: TamaIcons.names[i + offset])
            iconView.alpha = inactiveAlpha
        }
    }

    func updateIconState(icons: TamaIcons) {
        let offset = isBottomIconBar ? numIcons : 0
        for i in 0 ..< numIcons {
            let iconView = iconViews[i]
            let testIcon = TamaIcons.fromIndex(i + offset)
            iconView.alpha = icons.contains(testIcon) ? activeAlpha : inactiveAlpha
        }
    }

}