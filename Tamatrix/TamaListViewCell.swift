//
//  TamaListViewCell.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListViewCell: UICollectionViewCell {

    @IBOutlet var bgImageView: UIImageView!
    @IBOutlet var lcdImageView: TamaLcdImageView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Not used; no need to implement.
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let bgFrame = CGRect(x: 0, y: 0, width: 270, height: 330)
        bgImageView = UIImageView(frame: bgFrame)
        bgImageView.image = UIImage(named: "hexagon.png")
        contentView.addSubview(bgImageView)

        let lcdFrame = CGRect(x: 15, y: 85, width: 240, height: 160)
        lcdImageView = TamaLcdImageView(frame: lcdFrame, pixelSize: 5)
        contentView.addSubview(lcdImageView)
    }

}