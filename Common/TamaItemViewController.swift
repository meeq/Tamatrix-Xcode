//
//  TamaItemViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaItemViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var lcdImageView: TamaLcdImageView!

    var tamaId: Int = 0

    func tamaDataDidUpdate(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            let tamaData = sender.object as! [Int: NSDictionary]
            self.lcdImageView.setTamaData(tamaData[self.tamaId])
        }
    }

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

