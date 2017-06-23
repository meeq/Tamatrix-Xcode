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

    @IBOutlet weak var lcdImageView: UIImageView!

    var tamaId: Int = 0

    func tamaDataDidUpdate(_ sender: AnyObject) {
        let tamaData = sender.object as! [Int: TamaModel]
        if let tamaModel = tamaData[tamaId] {
            redrawLcdAsync(with: tamaModel.pixels)
        }
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

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Register for data update notifications
        NotificationCenter.default.addObserver(self,
            selector: #selector(TamaItemViewController.tamaDataDidUpdate(_:)),
            name: NSNotification.Name(rawValue: TamaDataUpdateNotificationKey),
            object: nil)
    }

    deinit {
        // Stop listening for data updates
        NotificationCenter.default.removeObserver(self)
    }
    
}

