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
        let tamaData = sender.object as! [Int: NSDictionary]
        // Update the LCD image on the main thread
        dispatch_async(dispatch_get_main_queue()) {
            self.lcdImageView.setTamaData(tamaData[self.tamaId])
        }
    }

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Register for data update notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    deinit {
        // Stop listening for data updates
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

