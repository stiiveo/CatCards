//
//  SingleImageVC.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/9/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class SingleImageVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var selectedCellIndex: Int = 0
    var imageScrollView: ImageScrollView!
    var currentPage: Int {
        Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    var previousPage = Int()
    let databaseManager = DatabaseManager()
    var imageViews = [ImageScrollView()] // ImageViews cache used to populate stackView
    let defaultImage = UIColor.white.image() // Default image used as default image in stackView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        disableTwoFingerScroll() // Prevent scrollView from responding to two-finger panning events
        removeImageView(at: 0) // Remove the template imageView set up in storyboard interface
        setupToolbar()
        
        /// TEST AREA
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Populate cache array with same amount of ImageScrollView object as the total image number and set default image to each object
        imageViews = (1...DatabaseManager.imageFilePaths.count).map { _ in
            let imageView = ImageScrollView(frame: view.bounds)
            imageView.set(image: defaultImage)
            return imageView
        }
        
        generateTemplateImageViews()
        setImages(at: selectedCellIndex)
        setScrollViewOffset() // Scroll to show the user selected image
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Clear the memory buffer of stackView's arranged subviews
        for arrangedSubview in stackView.arrangedSubviews {
            arrangedSubview.removeFromSuperview()
        }
    }
    
    //MARK: - Image Loading & Zoom Scale Control
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.previousPage = self.currentPage // Save the index of scrollView's page before it's changed by the user
    }
    
    /// Dynamically load/unload images and control the total number of arranged subviews in the stackView to limit the system memory usage
    /// - Parameter scrollView: The scroll-view object that is decelerating the scrolling of the content view.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard currentPage != previousPage else { return }
        
        // Reset zoom scale
        let previousImage = stackView.arrangedSubviews[previousPage] as! ImageScrollView
        previousImage.zoomScale = previousImage.minimumZoomScale
        
        if currentPage > previousPage { // User swipes to next imageView
            setImages(at: currentPage) // Set current and 4 nearby imageView image respectively
            if currentPage > 2 { // Current index number is 3 or more
                // Reset the imageView 3 index before the current imageView with default image
                if let imageViewToReset = stackView.arrangedSubviews[currentPage - 3] as? ImageScrollView {
                    imageViewToReset.set(image: defaultImage)
                }
            }
            
        } else if currentPage < previousPage { // User swipes to previous imageView
            setImages(at: currentPage) // Set current and 4 nearby imageView image respectively
            let lastIndex = stackView.arrangedSubviews.count - 1
            if currentPage < lastIndex - 2 { // Current index is 2 short of the last index number
                // Reset the imageView 3 index behind the current imageView with default image
                if let imageViewToReset = stackView.arrangedSubviews[currentPage + 3] as? ImageScrollView {
                    imageViewToReset.set(image: defaultImage)
                }
            }
        }
    }
    
    //MARK: - StackView Subview Loading
    
    /// Load ImageScrollView objects from cached array of 'imageViews' into stackView
    private func generateTemplateImageViews() {
        for index in 0...(DatabaseManager.imageFilePaths.count - 1) {
            stackView.addArrangedSubview(imageViews[index])
            imageViews[index].widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor).isActive = true
            imageViews[index].heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor).isActive = true
        }
    }
    
    private func setImages(at index: Int) {
        for index in (index - 2)...(index + 2) { // Load 5 images from disk where the third image is the user selected one
            guard 0 <= index && index < DatabaseManager.imageFilePaths.count else { continue } // Ensure index is within the bound of array
            
            let filePath = DatabaseManager.imageFilePaths[index]
            if let imageFromDisk = UIImage(contentsOfFile: filePath) {
                // Skip image loading process if the image has already been cached.
                if let existingImage = imageViews[index].imageZoomView.image {
                    guard !existingImage.isEqual(imageFromDisk) else { continue }
                }
                imageViews[index].set(image: imageFromDisk) // Set image to imageView at valid index value
            }
            
        }
    }
    
    //MARK: - ScrollView Behavior Setting
    
    private func setScrollViewOffset() {
        DispatchQueue.main.async {
            let frameWidth = self.scrollView.frame.width
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.selectedCellIndex) * frameWidth, y: 0), animated: false)
        }
    }
    
    private func disableTwoFingerScroll() {
        let twoFingerPan = UIPanGestureRecognizer()
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        self.scrollView.addGestureRecognizer(twoFingerPan)
    }
    
    //MARK: - ImageView Deletion Methods
    
    /// Stack view will be scrolled to the next page if the deleted view is not the last one in the stackView
    private func scrollAndRemoveImageView() {
        let originalPage = currentPage
        var pageToScroll: Int?
        let subviewCount = stackView.arrangedSubviews.count
        if subviewCount > 1 {
            if currentPage != subviewCount - 1 { // Scroll to right if current page is NOT the last arranged subview
                pageToScroll = currentPage + 1
            } else { // Scroll to left if current page is the last one in the stackView
                pageToScroll = currentPage - 1
            }
        } else if subviewCount == 1 { // Only one subview is left in the stackView
            // Go back to collection view
            self.navigationController?.popViewController(animated: true)
        }
        
        // Animate scrolling effect and remove the subview
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
                // Set the current view's alpha to 0
                self.stackView.arrangedSubviews[self.currentPage].alpha = 0
                
                // Scroll to the left/right imageView
                if let pageIndex = pageToScroll {
                    self.scrollView.contentOffset = CGPoint(x: CGFloat(pageIndex) * self.scrollView.frame.width, y: 0)
                }
            } completion: { (success) in
                if success {
                    self.removeImageView(at: originalPage) // Remove imageView from the stackView
                    
                    // Compensate scroll view's content offset after the imageView is removed from stackView
                    if pageToScroll == originalPage + 1 {
                        self.scrollView.contentOffset = CGPoint(x: CGFloat(originalPage) * self.scrollView.frame.width, y: 0)
                    }
                }
            }
        }
    }
    
    private func removeImageView(at index: Int) {
        let viewToDelete = stackView.arrangedSubviews[index]
        stackView.removeArrangedSubview(viewToDelete)
        viewToDelete.removeFromSuperview()
    }
    
    //MARK: - Toolbar Button Methods
    
    @objc func shareButtonPressed() {
        let filePath = DatabaseManager.imageFilePaths[currentPage]
        if let imageToShare = UIImage(contentsOfFile: filePath) {
            // present activity controller
            let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
            self.present(activityController, animated: true)
        }
    }
    
    @objc func deleteButtonPressed() {
        let alert = UIAlertController(title: "This action can not be reverted.", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Image", style: .destructive) { (action) in
            
            let savedDataList = self.databaseManager.listOfFileNames()
            let dataID = savedDataList[self.currentPage]
            
            // Delete data in file system, database and refresh the imageArray
            self.databaseManager.deleteData(id: dataID, atIndex: self.currentPage)
            
            // Animate the scroll view
            self.scrollAndRemoveImageView()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            return
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Stack View & Toolbar Preparation
    
    private func setupToolbar() {
        self.navigationController?.isToolbarHidden = false
        self.navigationController?.toolbar.clipsToBounds = true
        self.navigationController?.toolbar.isTranslucent = false
        
        var items = [UIBarButtonItem]()
        let shareItem = UIBarButtonItem(image: K.ButtonImage.share, style: .plain, target: self, action: #selector(shareButtonPressed))
        let deleteItem = UIBarButtonItem(image: K.ButtonImage.trash, style: .plain, target: self, action: #selector(deleteButtonPressed))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 50
        items = [fixedSpace, shareItem, flexibleSpace, deleteItem, fixedSpace] // Distribution of items in toolbar
        self.toolbarItems = items
        
        // Style
        self.navigationController?.toolbar.barTintColor = K.Color.backgroundColor
        self.navigationController?.toolbar.tintColor = K.Color.toolbarItem
    }
    
}

extension UIColor {
    /// Simple way to generate solid-color UIimage object
    /// Demo code: *let image0 = UIColor.orange.image(CGSize(width: 128, height: 128)); let image1 = UIColor.yellow.image()*
    /// - Parameter size: *Optional*: Default size is CGSize(width: 1, height: 1)
    /// - Returns: UIImage object with designated color
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
