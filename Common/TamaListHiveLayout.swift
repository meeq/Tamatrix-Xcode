//
//  TamaListHiveLayout.swift
//  Tamatrix
//
//  Created by Christopher Bonhage on 12/10/15.
//  Copyright © 2015 Christopher Bonhage. All rights reserved.
//

import UIKit

class TamaListHiveLayout: UICollectionViewFlowLayout {

    private var cache = [UICollectionViewLayoutAttributes]()
    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0

    override func prepareLayout() {
        cache.removeAll()

        contentWidth = CGRectGetWidth(collectionView!.bounds)
        // TODO Fix hard-coded layout sizes to support iOS devices
        let verticalMargin: CGFloat = 50
        let leftMargin: CGFloat = 150
        let rightMargin: CGFloat = contentWidth - leftMargin
        let cellWidth: CGFloat = 270
        let cellHeight: CGFloat = 330
        let cellXPadding: CGFloat = 60
        let cellYPadding: CGFloat = 0
        var xOffset: CGFloat = leftMargin
        var yOffset: CGFloat = verticalMargin
        var insetRow: Bool = false
        var emptyRow: Bool = true

        for item in 0 ..< collectionView!.numberOfItemsInSection(0) {
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            let itemAttrs = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            itemAttrs.frame = CGRect(x: xOffset, y: yOffset, width: cellWidth, height: cellHeight)
            cache.append(itemAttrs)
            emptyRow = false

            xOffset += cellXPadding + cellWidth
            if xOffset + cellWidth > rightMargin {
                yOffset += cellYPadding + cellHeight
                xOffset = leftMargin
                insetRow = !insetRow
                emptyRow = true
                if insetRow {
                    xOffset += cellHeight / 2
                }
            }
        }
        contentHeight = yOffset + verticalMargin
        if !emptyRow {
            contentHeight += cellHeight
        }
    }

    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if CGRectIntersectsRect(attributes.frame, rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }

}
