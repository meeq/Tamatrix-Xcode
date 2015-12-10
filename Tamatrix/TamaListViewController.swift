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

    var lastseq: Int = -1
    var notama: Int = 0
    var tama: [Int: NSDictionary]!

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the view controller
        self.collectionView.registerClass(TamaListViewCell.self, forCellWithReuseIdentifier: "TamaItemViewCell")
        self.tama = [Int: NSDictionary]()
        self.fetchData()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // TODO Configure ItemViewController for selection
        if let selection = collectionView.indexPathsForSelectedItems() {
            let itemViewController = segue.destinationViewController as! TamaItemViewController
            itemViewController.setItem(selection.first!)
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.notama;
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // TODO Set up a real cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TamaItemViewCell", forIndexPath: indexPath) as! TamaListViewCell

        return cell
    }

    // MARK: Data Helpers

    func fetchData() {
        let url = NSURL(string: "http://127.0.0.1/tamaweb/gettama.php")
        print("Fetching data: \(url!.absoluteString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { data, response, error in
            guard data != nil else {
                print("Request failed: \(error)")
                return
            }
            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            do {
                if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                    self.processData(json)
                } else {
                    print("Could not parse JSON: \(jsonStr)")
                }
            } catch let parseError {
                print("Parse error for JSON: \(jsonStr)")
                print(parseError)
            }
        }
        task.resume()
    }

    func processData(data: NSDictionary) {
        self.lastseq = data["lastseq"] as! Int
        self.notama = data["notama"] as! Int
        self.tama.removeAll()
        for entry in data["tama"] as! [NSDictionary] {
            let id = entry["id"] as! Int
            self.tama[id] = entry
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
            print("Reloading collection view")
        }
    }


}

