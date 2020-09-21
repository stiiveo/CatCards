//
//  CollectionVC.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/11.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CollectionVC: UICollectionViewController {
    
    let favDataManager = DatabaseManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        let screenWidth = UIScreen.main.bounds.width
        let cellNumberPerRow: CGFloat = 3.0
        let interCellSpacing: CGFloat = 1.5
        let cellWidth = (screenWidth - (interCellSpacing * (cellNumberPerRow - 1))) / cellNumberPerRow
        // floor the calculated width to remove any possible decimal number
        let flooredCellWidth = floor(cellWidth)
        
        // set up width and spacing of each cell
        let viewLayout = self.collectionViewLayout
        let flowLayout = viewLayout as! UICollectionViewFlowLayout
        // remove auto layout constraint
        flowLayout.estimatedItemSize = .zero
        flowLayout.itemSize = CGSize(width: flooredCellWidth, height: flooredCellWidth)
        flowLayout.minimumLineSpacing = interCellSpacing
        
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DatabaseManager.imageArray.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionCell.cellIdentifier, for: indexPath) as! CollectionCell

        // Configure each cell's imageView
        cell.imageView.image = DatabaseManager.imageArray[indexPath.item]

        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
