//
//  CollectionVC.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/8/11.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import ImageIO

class CollectionVC: UICollectionViewController {
    
    private var selectedCellIndex: Int = 0
    private let screenWidth = UIScreen.main.bounds.width
    private let backgroundLayer = CAGradientLayer()
    private lazy var noSavedPicturesHint: UILabel = {
        let label = UILabel()
        label.text = Z.BackgroundView.noDataLabel
        label.font = .boldSystemFont(ofSize: 18)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        
        return label
    }()
    
    // Device with wider screen (iPhone Plus and Max series) has one more cell per row than other devices
    private var cellNumberPerRow: CGFloat {
        if screenWidth >= 414 {
            return 4.0
        } else {
            return 3.0
        }
    }
    
    //MARK: - View Overriding Methods

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
    }
    
    // Refresh the collection view every time the view is about to be shown to the user
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
        
        addBackgroundView()
        setBackgroundColor()
        noSavedPicturesHint.alpha = (DatabaseManager.imageFileURLs.count == 0) ? 1 : 0
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.selectedCellIndex = self.selectedCellIndex
        }
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
    
    //MARK: - Background View & Color
    
    private func setBackgroundColor() {
        let interfaceStyle = traitCollection.userInterfaceStyle
        let lightModeColors = [K.Color.lightModeColor1, K.Color.lightModeColor2]
        let darkModeColors = [K.Color.darkModeColor1, K.Color.darkModeColor2]
        
        backgroundLayer.colors = (interfaceStyle == .light) ? lightModeColors : darkModeColors
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Make background color respond to change of interface style
        setBackgroundColor()
    }
    
    private func addBackgroundView() {
        let backgroundView = UIView(frame: view.bounds)
        backgroundLayer.frame = view.bounds
        
        // Add a gradient color layer
        backgroundView.layer.insertSublayer(backgroundLayer, at: 0)
        
        // Add No-pictures-saved hint
        backgroundView.addSubview(noSavedPicturesHint)
        noSavedPicturesHint.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Leave some margin on both sides
            noSavedPicturesHint.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            noSavedPicturesHint.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20),
            noSavedPicturesHint.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
        ])
        
        collectionView.backgroundView = backgroundView
    }

}
