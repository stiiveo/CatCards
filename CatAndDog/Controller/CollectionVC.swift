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
    
    private let screenWidth = UIScreen.main.bounds.width
    private var selectedCellIndex: Int = 0
    
    // Device with wider screen (iPhone Plus and Max series) has one more cell per row than other devices
    private var cellNumberPerRow: CGFloat {
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
        
        if DatabaseManager.imageFileURLs.count == 0 {
            let label = defaultLabel() // Display default message on the background
            collectionView.backgroundView = label
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.selectedCellIndex = self.selectedCellIndex
        }
    }

    private func defaultLabel() -> UILabel {
        let noDataLabel = UILabel()
        self.collectionView.addSubview(noDataLabel)
        NSLayoutConstraint.activate([
            noDataLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 20),
            noDataLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -20),
            noDataLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
        
        noDataLabel.text = Z.BackgroundView.noDataLabel
        noDataLabel.font = .boldSystemFont(ofSize: 20)
        noDataLabel.adjustsFontSizeToFitWidth = true
        noDataLabel.minimumScaleFactor = 0.7
        noDataLabel.numberOfLines = 0
        noDataLabel.textColor = UIColor.systemGray
        noDataLabel.textAlignment = .center
        
        return noDataLabel
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DatabaseManager.imageFileURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Expected `\(Cell.self)` type for reuseIdentifier \(Cell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        let thumbnailURL = DatabaseManager.imageFileURLs[indexPath.row].thumbnail
        cell.imageView.image = UIImage(contentsOfFile: thumbnailURL.path)
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.row
        performSegue(withIdentifier: K.SegueIdentifiers.collectionToSingle, sender: self)
    }

}
