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

    func tamaDataDidUpdate(_ sender: AnyObject) {
        guard let collectionView = collectionView else { return }
        tamaData = sender.object as! [Int: TamaModel]
        if cellCount != tamaData.count {
            cellCount = tamaData.count
            DispatchQueue.main.async {
                collectionView.reloadData()
            }
        } else {
            redrawVisibleCells()
        }
    }

    func redrawVisibleCells() {
        guard let collectionView = collectionView else { return }
        // Update the pixel data for all visible LCDs
        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? TamaListViewCell {
                if let tamaModel = tamaData[indexPath.item] {
                    cell.redrawLcdAsync(with: tamaModel.pixels)
                }
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Listen for data-change events
        NotificationCenter.default.addObserver(self,
            selector: #selector(TamaListViewController.tamaDataDidUpdate(_:)),
            name: NSNotification.Name(rawValue: TamaDataUpdateNotificationKey),
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Configure ItemViewController for indexed selection
        if let indexPath = collectionView!.indexPathsForSelectedItems?.first {
            let itemViewController = segue.destination as! TamaItemViewController
            if let tamaModel = tamaData[indexPath.item] {
                itemViewController.tamaId = tamaModel.id
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellCount;
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TamaListViewCell", for: indexPath) as! TamaListViewCell
        cell.centerAndResizeLcdImageView() // TODO Use constraints
        if let tamaModel = tamaData[indexPath.item] {
            cell.redrawLcdAsync(with: tamaModel.pixels)
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }

}

