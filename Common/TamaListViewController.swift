//
//  TamaListViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListViewController: UICollectionViewController {

    // MARK: Properties

    var tamaData = [Int: NSDictionary]()

    func tamaDataDidUpdate(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            let oldData = self.tamaData
            self.tamaData = sender.object as! [Int: NSDictionary]
            if oldData.count != self.tamaData.count {
                self.collectionView?.reloadData()
            } else {
                self.redrawVisibleCells()
            }
        }
    }

    func redrawVisibleCells() {
        if let collectionView = self.collectionView {
            for indexPath in collectionView.indexPathsForVisibleItems() {
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! TamaListViewCell
                cell.lcdImageView.setTamaData(self.tamaData[indexPath.item])
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
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
        if let indexPath = collectionView!.indexPathsForSelectedItems()?.first {
            let itemViewController = segue.destinationViewController as! TamaItemViewController
            if let entry: NSDictionary = self.tamaData[indexPath.item] {
                itemViewController.tamaId = entry["id"] as! Int
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tamaData.count;
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            "TamaListViewCell", forIndexPath: indexPath) as! TamaListViewCell
        cell.lcdImageView.setTamaData(self.tamaData[indexPath.item])
        return cell
    }

    override func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

}

