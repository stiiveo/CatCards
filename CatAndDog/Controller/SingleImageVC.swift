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
    private var currentPage: Int = 0 {
        didSet(oldPage) {
            if currentPage > oldPage {
                updateImage(at: .forward)
            }
            if currentPage < oldPage {
                updateImage(at: .backward)
            }
        }
    }
    private var previousPage: Int = 0
    private var bufferImageArray = [ImageScrollView()] // ImageViews cache used to populate stackView
    private let bufferImageNumber: Int = K.Data.maxBufferImageNumber
    private let defaultImage = UIColor.systemGray5.image(CGSize(width: 400, height: 400)) // Default image in stackView
    
    private enum ScrollDirection {
        case forward, backward
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        disableTwoFingerScroll() // Prevent scrollView from responding to two-finger panning events
        removeImageView(at: 0) // Remove the template imageView set up in storyboard interface
        setupToolbar()
        
        /// TEST AREA
    }
    
    override func viewWillAppear(_ animated: Bool) {
        initiateImageBufferArray() // Create imageView cache
        loadDefaultImageView() // Populate cache array with default imageViews
        
        // Load images to selected imageView and nearby ones
        for index in (selectedCellIndex - (bufferImageNumber / 2))...(selectedCellIndex + (bufferImageNumber / 2)) {
            setImage(at: index)
        }
        
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
        previousPage = currentPage // Save the index of scrollView's page before it's changed by the user
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    
    /// Dynamically load/unload images and control the total number of arranged subviews in the stackView to limit the system memory consumption
    /// - Parameter scrollView: The scroll-view object that is decelerating the scrolling of the content view.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard currentPage != previousPage else { return } // Make sure the page is changed
        // Reset zoom scale
        let previousImage = stackView.arrangedSubviews[previousPage] as! ImageScrollView
        previousImage.zoomScale = previousImage.minimumZoomScale
        
    }
    
    //MARK: - StackView Image Loading
    
    /// Load image from disk and reset buffered image.
    ///
    /// When user scrolls to next / previous page, the image which index is within the buffer range is loaded from local disk and the one outside the buffer range is reset.
    /// - Parameter direction: User's scrolling direction: Either 'forward' or 'backward'
    private func updateImage(at direction: ScrollDirection) {
        switch direction {
        case .forward:
            // Update imageView ahead of current page
            setImage(at: currentPage + (bufferImageNumber / 2))
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage - (bufferImageNumber / 2) - 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.set(image: defaultImage)
            }
        case .backward:
            // Update imageView before the current page
            setImage(at: currentPage - (bufferImageNumber / 2))
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage + (bufferImageNumber / 2) + 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.set(image: defaultImage)
            }
        }
    }
    
    /// Load image at designated index from local disk to memory buffer
    /// - Parameter index: Image's index number of the image buffer array
    private func setImage(at index: Int) {
        // Ensure index is within the bound of array
        guard 0 <= index && index < DatabaseManager.imageFilePaths.count else { return }
        
        let filePath = DatabaseManager.imageFilePaths[index]
        guard let imageAtDisk = UIImage(contentsOfFile: filePath) else { return }
            
        bufferImageArray[index].set(image: imageAtDisk) // Set image to imageView at valid index value
    }
    
    /// Create an `ImageScrollView` array with same item number as local saved image number and set each object's image property the default image defined in this class
    private func initiateImageBufferArray() {
        bufferImageArray = (1...DatabaseManager.imageFilePaths.count).map { _ in
            let imageView = ImageScrollView(frame: view.bounds)
            imageView.set(image: defaultImage)
            return imageView
        }
    }
    
    /// Load ImageScrollView objects from cached array of 'imageViews' into stackView
    private func loadDefaultImageView() {
        for index in 0...(DatabaseManager.imageFilePaths.count - 1) {
            stackView.addArrangedSubview(bufferImageArray[index])
            bufferImageArray[index].widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor).isActive = true
            bufferImageArray[index].heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor).isActive = true
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
                
                // Scroll to next/previous imageView
                if let pageIndex = pageToScroll {
                    self.scrollView.contentOffset = CGPoint(x: CGFloat(pageIndex) * self.scrollView.frame.width, y: 0)
                }
            } completion: { _ in
                self.removeImageView(at: originalPage) // Remove imageView from the stackView
                
                // Compensate scroll view's content offset after the imageView is removed from stackView
                if pageToScroll == originalPage + 1 {
                    self.scrollView.contentOffset = CGPoint(x: CGFloat(originalPage) * self.scrollView.frame.width, y: 0)
                }
            }
        }
    }
    
    private func removeImageView(at index: Int) {
        let viewToDelete = stackView.arrangedSubviews[index]
        stackView.removeArrangedSubview(viewToDelete)
        viewToDelete.removeFromSuperview()
        bufferImageArray.remove(at: index) // Remove cached imageView
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
            
            let databaseManager = DatabaseManager()
            let savedDataList = databaseManager.listOfFileNames()
            let dataID = savedDataList[self.currentPage]
            
            // Delete data in file system, database and refresh the imageArray
            databaseManager.deleteData(id: dataID, atIndex: self.currentPage)
            
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
    /// Simplified way to create a solid-color UIimage object with set size
    ///
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
