//
//  TamaLcdImageView.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaLcdImageView: UIView {

    var screenData: String?

    func setTamaData(entry: NSDictionary?) {
        guard entry != nil else {
            return
        }
        self.screenData = entry!["pixels"] as? String
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        guard self.screenData != nil else {
            return
        }
        tamaDrawLcdInCurrentCGContext(self.screenData!, size: self.frame.size)
        
    }
    
}
