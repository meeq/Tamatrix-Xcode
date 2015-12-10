//
//  ListViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    // MARK: Properties

    @IBOutlet weak var collectionView: UICollectionView!

    var tamaData = [Int: NSDictionary]()

    func tamaDataDidUpdate(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.tamaData = sender.object as! [Int: NSDictionary]
            self.collectionView.reloadData()
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the view controller
        self.collectionView.remembersLastFocusedIndexPath = true
        // Listen for data-change events
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "tamaDataDidUpdate:",
            name: TamaDataUpdateNotificationKey,
            object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // TODO Configure ItemViewController for selection
        if let indexPath = collectionView.indexPathsForSelectedItems()?.first {
            let itemViewController = segue.destinationViewController as! TamaItemViewController
            if let entry: NSDictionary = self.tamaData[indexPath.item] {
                itemViewController.tamaId = entry["id"] as! Int
            }
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tamaData.count;
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "TamaListViewCell", forIndexPath: indexPath) as! TamaListViewCell
        if let entry: NSDictionary = self.tamaData[indexPath.item] {
            cell.lcdImageView.screenData = entry["pixels"] as? String
            cell.lcdImageView.setNeedsDisplay()
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

}

