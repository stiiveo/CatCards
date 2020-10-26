//
//  CollectionVC.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/11.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CollectionVC: UICollectionViewController {
    
    var selectedCellIndex: Int?
    var reversedImageArray = [UIImage]()
    let screenWidth = UIScreen.main.bounds.width
    
    // Device with wider screen (iPhone Plus and Max series) has one more cell per row than other devices
    var cellNumberPerRow: CGFloat {
        if screenWidth >= 414 {
            return 4.0
        } else {
            return 3.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /// Set up cell's size and spacing
        
        let interCellSpacing: CGFloat = 1.5
        let cellWidth = (screenWidth - (interCellSpacing * (cellNumberPerRow - 1))) / cellNumberPerRow
        
        // Floor the calculated width to remove any decimal number
        let flooredCellWidth = floor(cellWidth)
        
        // Set up width and spacing of each cell
        let viewLayout = self.collectionViewLayout
        let flowLayout = viewLayout as! UICollectionViewFlowLayout
        
        // Remove auto layout constraint
        flowLayout.estimatedItemSize = .zero
        flowLayout.itemSize = CGSize(width: flooredCellWidth, height: flooredCellWidth)
        flowLayout.minimumLineSpacing = interCellSpacing
        
        // TEST AREA
        
    }
    
    // Refresh the collection view every time the view is about to be shown to the user
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
        self.navigationController?.navigationBar.barTintColor = K.Color.backgroundColor
        self.navigationController?.isToolbarHidden = true
        
        if DatabaseManager.imageArray.count == 0 {
            let label = getDefaultLabel()
            collectionView.backgroundView = label
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.selectedIndex = selectedCellIndex
            destination.imageArray = reversedImageArray
        }
    }

    private func getDefaultLabel() -> UILabel {
        let noDataLabel = UILabel(frame: CGRect(x: 0,
                                                y: 0,
                                                width: collectionView.bounds.size.width,
                                                height: collectionView.bounds.size.height)
        )
        noDataLabel.text = "   Your Favorite Cat Images Are Right Here   "
        noDataLabel.font = .boldSystemFont(ofSize: 18)
        noDataLabel.adjustsFontSizeToFitWidth = true
        noDataLabel.minimumScaleFactor = 0.7
        noDataLabel.textColor = UIColor.systemGray
        noDataLabel.textAlignment = .center
        return noDataLabel
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
        let savedImages = DatabaseManager.imageArray
        let reversedArray: [UIImage] = Array(savedImages.reversed())
        cell.imageView.image = reversedArray[indexPath.item]
        reversedImageArray = reversedArray // Used for single view controller
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.row
        performSegue(withIdentifier: K.SegueIdentifier.collectionToSingle, sender: self)
    }

}
