//
//  TamaEmuViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/30/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaEmuViewController: UIViewController {

    private var tamaState: TamaEmulatorState?

    @IBOutlet weak var lcdView: TamaLcdView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Listen for data-change events
        NotificationCenter.default.addObserver(self,
            selector: #selector(TamaEmuViewController.tamaStateDidUpdate(_:)),
            name: NSNotification.Name(rawValue: TamaStateUpdateNotificationKey),
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func tamaStateDidUpdate(_ sender: AnyObject) {
        guard let tamaState = sender.object as? TamaEmulatorState else { return }
        self.tamaState = tamaState
        lcdView.setState(tamaState)
    }

    @IBAction func userDidPressButton(_ sender: UIButton) {
        if let text = sender.titleLabel?.text {
            tamaState?.pressButton(TamaButton.fromString(text))
        }
    }

}

