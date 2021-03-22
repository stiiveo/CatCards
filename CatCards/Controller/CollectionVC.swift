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
    
    private let databaseManager = DatabaseManager.shared
    private var selectedCellIndex: Int = 0
    private let backgroundLayer = CAGradientLayer()
    private var backgroundView: UIView!
    private var navBar: UINavigationBar!
    private var flowLayout: UICollectionViewFlowLayout!
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
    
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    // To maximize the usage of screen real estate, the wider the screen width, the more cell numbers per row of the collection view
    private var numberOfCellsPerRow: CGFloat {
        switch screenWidth {
        case 0..<414:
            return 3
        case 414..<768:
            return 4
        case 768..<1024:
            return 5
        default:
            return 6
        }
    }
    
    //MARK: - View Overriding Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        navBar = self.navigationController?.navigationBar
        flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout
        addBackgroundView()
    }
    
    // Refresh the collection view every time the view is about to be shown to the user
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBar.setBackgroundImage(nil, for: .default)
        navBar.barTintColor = K.Color.backgroundColor
        backgroundLayer.frame = view.bounds
        
        collectionView.reloadData()
        
        // Display background view if no picture is saved yet
        noSavedPicturesHint.alpha = (databaseManager.imageFileURLs.count == 0) ? 1 : 0
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateCollectionViewItemSize()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Update the frame of the background layer
            self.backgroundLayer.frame = self.view.bounds
        }, completion: nil)
        
        flowLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navBar.setBackgroundImage(UIImage(), for: .default)
    }
    
    // Send the selected cell index to the SingleImageVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SingleImageVC {
            destination.selectedCellIndex = self.selectedCellIndex
        }
    }
    
    //MARK: - Collection View Item Size
    
    private func updateCollectionViewItemSize() {
        /// Set up cell's size and spacing
        let interCellSpacing: CGFloat = 1.5
        let width = (screenWidth - (interCellSpacing * (numberOfCellsPerRow - 1))) / numberOfCellsPerRow
        let height = width
        
        // Set up width and spacing of each cell
        
        // Remove auto layout constraint
        flowLayout.estimatedItemSize = .zero
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumLineSpacing = interCellSpacing
        flowLayout.minimumInteritemSpacing = interCellSpacing
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return databaseManager.imageFileURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Expected `\(Cell.self)` type for reuseIdentifier \(Cell.reuseIdentifier). Check the configuration in Main.storyboard.")
        }
        let thumbnailURL = databaseManager.imageFileURLs[indexPath.row].thumbnail
        cell.imageView.image = UIImage(contentsOfFile: thumbnailURL.path)
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.row
        performSegue(withIdentifier: K.SegueIdentifiers.collectionToSingle, sender: self)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    //MARK: - Background View & Color
    
    private func setBackgroundLayerColor() {
        let interfaceStyle = traitCollection.userInterfaceStyle
        let lightModeColors = [K.Color.lightModeColor1, K.Color.lightModeColor2]
        let darkModeColors = [K.Color.darkModeColor1, K.Color.darkModeColor2]
        
        backgroundLayer.colors = (interfaceStyle == .light) ? lightModeColors : darkModeColors
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Make background color respond to change of interface style
        setBackgroundLayerColor()
    }
    
    // Background view is composed with a UIView at the bottom with a gradient–color layer on top
    private func addBackgroundView() {
        backgroundView = UIView(frame: view.bounds)
        backgroundLayer.frame = view.bounds
        
        // Add a gradient color layer
        setBackgroundLayerColor()
        backgroundView.layer.insertSublayer(backgroundLayer, at: 0)
        
        // Add no-saved-pictures label to background view
        addHintLabel(to: backgroundView)
        
        collectionView.backgroundView = backgroundView
    }
    
    private func addHintLabel(to view: UIView) {
        view.addSubview(noSavedPicturesHint)
        noSavedPicturesHint.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Leave some margin on both sides
            noSavedPicturesHint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noSavedPicturesHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            noSavedPicturesHint.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

}
