//
//  TamaLcdImageView.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaLcdImageView: UIView {

    private var screenData: String?

    func setTamaData(entry: NSDictionary?) {
        if let pixelData = entry?["pixels"] as? String {
            self.screenData = pixelData
            self.setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        if let pixelData = self.screenData {
            let ctx: CGContextRef = UIGraphicsGetCurrentContext()!
            tamaDrawLcdInCGContext(ctx, data: pixelData, size: self.frame.size)
        }
    }
    
}
