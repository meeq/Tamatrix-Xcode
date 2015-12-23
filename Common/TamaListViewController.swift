//
//  TamaListViewController.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/9/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListViewController: UICollectionViewController {

    private var tamaData = [Int: TamaModel]()
    private var cellCount: Int = 0

    func tamaDataDidUpdate(sender: AnyObject) {
        self.tamaData = sender.object as! [Int: TamaModel]
        if self.cellCount != self.tamaData.count {
            self.cellCount = self.tamaData.count
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView?.reloadData()
            }
        } else {
            self.redrawVisibleCells()
        }
    }

    func redrawVisibleCells() {
        if let collectionView = self.collectionView {
            // Update the pixel data for all visible LCDs
            for indexPath in collectionView.indexPathsForVisibleItems() {
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! TamaListViewCell
                if let tamaModel = self.tamaData[indexPath.item] {
                    cell.redrawLcdAsync(tamaModel.pixels)
                }
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
        // Configure ItemViewController for indexed selection
        if let indexPath = collectionView!.indexPathsForSelectedItems()?.first {
            let itemViewController = segue.destinationViewController as! TamaItemViewController
            if let tamaModel = self.tamaData[indexPath.item] {
                itemViewController.tamaId = tamaModel.id
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cellCount;
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TamaListViewCell", forIndexPath: indexPath) as! TamaListViewCell
        cell.centerAndResizeLcdImageView() // TODO Use constraints
        if let tamaModel = self.tamaData[indexPath.item] {
            cell.redrawLcdAsync(tamaModel.pixels)
        }
        return cell
    }

    override func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

}

