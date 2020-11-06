//
//  CollectionVC.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/11.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import ImageIO

class CollectionVC: UICollectionViewController {
    
    let screenWidth = UIScreen.main.bounds.width
    var selectedCellIndex: Int?
    let cellImages = DatabaseManager.thumbImages
    
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
        
        if cellImages.count == 0 {
            let label = defaultLabel() // Display default message on the background
            collectionView.backgroundView = label
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.selectedIndex = selectedCellIndex
        }
    }

    private func defaultLabel() -> UILabel {
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
        return cellImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Expected `\(Cell.self)` type for reuseIdentifier \(Cell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        cell.imageView.image = cellImages.reversed()[indexPath.row] // Reverse the order of image array so the last saved image is displayed first
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.row
        performSegue(withIdentifier: K.SegueIdentifier.collectionToSingle, sender: self)
    }

}
