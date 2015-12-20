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

    private let baseCellWidth: CGFloat = 270
    private let baseCellHeight: CGFloat = 330
    private let baseCellXPadding: CGFloat = 60
    private let baseCellYPadding: CGFloat = 0
    private let baseVertInset: CGFloat = 30

    private func computeNumCellsInFirstRowForWidth(contentWidth: CGFloat, cellWidth: CGFloat, cellPadding: CGFloat) -> CGFloat {
        var result: CGFloat = 1
        var xOffset: CGFloat = cellWidth
        let xIncrement: CGFloat = cellPadding + cellWidth
        while xOffset + xIncrement < contentWidth {
            xOffset += xIncrement
            result += 1
        }
        return result
    }

    override func prepareLayout() {
        cache.removeAll()

        contentWidth = CGRectGetWidth(collectionView!.bounds)
        let pixelScale: CGFloat = collectionView!.window!.screen.scale
        let cellWidth: CGFloat = baseCellWidth / pixelScale
        let cellHeight: CGFloat = baseCellHeight / pixelScale
        let cellXPadding: CGFloat = baseCellXPadding / pixelScale
        let cellYPadding: CGFloat = baseCellYPadding / pixelScale

        let cellsPerRow = computeNumCellsInFirstRowForWidth(contentWidth, cellWidth: cellWidth, cellPadding: cellXPadding)
        let firstRowCellsWidth = (cellWidth * (cellsPerRow)) + (cellXPadding * (cellsPerRow - 1))

        let verticalInset: CGFloat = baseVertInset / pixelScale
        let leftInset: CGFloat = (contentWidth - firstRowCellsWidth) / 2
        let rightInset: CGFloat = contentWidth - leftInset

        var xOffset: CGFloat = leftInset
        var yOffset: CGFloat = verticalInset
        var isStaggeredRow: Bool = false
        var isEmptyRow: Bool = true

        for item in 0 ..< collectionView!.numberOfItemsInSection(0) {
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            let itemAttrs = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            itemAttrs.frame = CGRectMake(xOffset, yOffset, cellWidth, cellHeight)
            cache.append(itemAttrs)
            isEmptyRow = false

            xOffset += cellXPadding + cellWidth
            if xOffset + cellWidth > rightInset {
                xOffset = leftInset
                yOffset += cellYPadding + cellHeight
                isEmptyRow = true
                isStaggeredRow = !isStaggeredRow
                if isStaggeredRow {
                    xOffset += cellHeight / 2
                }
            }
        }
        contentHeight = yOffset + verticalInset
        if !isEmptyRow {
            contentHeight += cellHeight
        }
    }

    override func collectionViewContentSize() -> CGSize {
        return CGSizeMake(contentWidth, contentHeight)
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
