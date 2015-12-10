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
    @IBOutlet var lcdImageView: UIImageView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Not used; no need to implement.
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        bgImageView = UIImageView(frame: frame)
        bgImageView.image = UIImage(named: "hexagon.png")
        contentView.addSubview(bgImageView)
    }

}