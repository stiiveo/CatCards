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
    var selectedCellIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        /// Set up cell's size and spacing
        
        let screenWidth = UIScreen.main.bounds.width
        let cellNumberPerRow: CGFloat = 3.0
        let interCellSpacing: CGFloat = 2.0
        let cellWidth = (screenWidth - (interCellSpacing * (cellNumberPerRow - 1))) / cellNumberPerRow
        
        // floor the calculated width to remove any decimal number
        let flooredCellWidth = floor(cellWidth)
        
        // set up width and spacing of each cell
        let viewLayout = self.collectionViewLayout
        let flowLayout = viewLayout as! UICollectionViewFlowLayout
        
        // remove auto layout constraint
        flowLayout.estimatedItemSize = .zero
        flowLayout.itemSize = CGSize(width: flooredCellWidth, height: flooredCellWidth)
        flowLayout.minimumLineSpacing = interCellSpacing
        
    }
    
    // Refresh the collection view every time the view is about to be shown to the user
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        self.collectionView.reloadData()
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.imageToShowIndex = selectedCellIndex
        }
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

        // Configure each cell's imageView in reversed order
        let images = DatabaseManager.imageArray
        let reversedArray: [UIImage] = Array(images.reversed())
        cell.imageView.image = reversedArray[indexPath.item]
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.row
        performSegue(withIdentifier: K.SegueIdentifier.collectionToSingle, sender: self)
    }
    

}
