//
//  SingleImageVC.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/9/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class SingleImageVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var selectedCellIndex: Int = 0
    private let backgroundLayer = CAGradientLayer()
    private var bufferImageArray = [ImageScrollView()] // ImageViews cache used to populate stackView
    private let bufferImageNumber: Int = K.Data.maxBufferImageNumber
    private let defaultCacheImage = K.Image.defaultCacheImage
    private var previousPage: Int = 0
    private let hapticManager = HapticManager()
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
    
    private enum ScrollDirection {
        case forward, backward
    }
    
    //MARK: - View Overriding Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        attachPanGestureRecognizer() // Prevent scrollView from responding to two-finger panning events
        removeImageView(atPage: 0) // Remove the template imageView set up in storyboard interface
        setToolbarStyle()
        
        // Add background layer
        backgroundLayer.frame = view.bounds
        view.layer.insertSublayer(backgroundLayer, at: 0)
        setBackgroundColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setToolbarStyle()
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
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
    /// When user scrolls to next / previous page, the image which index is within the buffer range is loaded from local disk
    /// while the one outside the buffer range is reset.
    /// - Parameter direction: User's scrolling direction: Either 'forward' or 'backward'
    private func updateImage(at direction: ScrollDirection) {
        let bufferImageEachSide = bufferImageNumber / 2 // Number of arranged subviews loaded with image on each side of current view
        switch direction {
        case .forward:
            // Update imageView ahead of current page
            setImage(at: currentPage + bufferImageEachSide)
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage - bufferImageEachSide - 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.set(image: defaultCacheImage)
            }
        case .backward:
            // Update imageView before the current page
            setImage(at: currentPage - bufferImageEachSide)
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage + bufferImageEachSide + 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.set(image: defaultCacheImage)
            }
        }
    }
    
    /// Load image at designated index from local disk to memory buffer
    /// - Parameter index: Image's index number of the image buffer array
    private func setImage(at index: Int) {
        // Ensure index is within the bound of array
        guard 0 <= index && index < DatabaseManager.imageFileURLs.count else { return }
        
        let imageFileURL = DatabaseManager.imageFileURLs[index].image
        guard let imageAtDisk = UIImage(contentsOfFile: imageFileURL.path) else { return }
            
        bufferImageArray[index].set(image: imageAtDisk) // Set image to imageView at valid index value
    }
    
    /// Create an `ImageScrollView` array with same item number as local saved image number and set each object's image property the default image defined in this class
    private func initiateImageBufferArray() {
        bufferImageArray = (1...DatabaseManager.imageFileURLs.count).map { _ in
            let imageView = ImageScrollView(frame: view.bounds)
            imageView.set(image: defaultCacheImage)
            return imageView
        }
    }
    
    /// Load ImageScrollView objects from cached array of 'imageViews' into stackView
    private func loadDefaultImageView() {
        for index in 0...(DatabaseManager.imageFileURLs.count - 1) {
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
    
    private func attachPanGestureRecognizer() {
        let twoFingerPan = UIPanGestureRecognizer()
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        self.scrollView.addGestureRecognizer(twoFingerPan)
    }
    
    //MARK: - ImageView Deletion Methods
    
    /// Stack view scrolls to right (next page) if the deleted view is not the last one in the stackView.
    private func scrollAndRemoveImageView() {
        let originalPage = currentPage
        var pageToScroll: Int?
        let subviewCount = stackView.arrangedSubviews.count
        if subviewCount > 1 {
            // Scroll to right if current page is NOT the last arranged subview, vice versa
            pageToScroll = (currentPage != subviewCount - 1) ? currentPage + 1 : currentPage - 1
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
                self.removeImageView(atPage: originalPage) // Remove imageView from the stackView
                
                // Compensate the reduced number of arranged stackView if stack view is scrolled to the next page
                if pageToScroll == originalPage + 1 {
                    self.scrollView.contentOffset = CGPoint(x: CGFloat(originalPage) * self.scrollView.frame.width, y: 0)
                    
                    // After reverting to original page, the 'auto buffer updating' method will move the buffer image (2 images after the current image) out of buffer range, which causes it to be reset and not being updated when user scrolls to the next page.
                    // Therefore, it's neccesary to update the image which was reset due to the compensation of page number change.
                    let bufferNumberAtEachSide = self.bufferImageNumber / 2
                    self.setImage(at: originalPage + bufferNumberAtEachSide)
                }
            }
        }
    }
    
    private func removeImageView(atPage index: Int) {
        let viewToDelete = stackView.arrangedSubviews[index]
        stackView.removeArrangedSubview(viewToDelete)
        viewToDelete.removeFromSuperview()
    }
    
    //MARK: - Toolbar Button Methods
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        let imageFileURLs = DatabaseManager.imageFileURLs
        guard currentPage >= 0 && currentPage < imageFileURLs.count else { return }
        
        hapticManager.prepareImpactGenerator(style: .soft)
        let imageURL = DatabaseManager.imageFileURLs[currentPage].image
        let activityVC = UIActivityViewController(activityItems: [imageURL], applicationActivities: nil)
        self.present(activityVC, animated: true)
        hapticManager.impactHaptic?.impactOccurred()
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        hapticManager.prepareNotificationGenerator()
        hapticManager.notificationHaptic?.notificationOccurred(.warning)
        
        let alert = UIAlertController(title: Z.AlertMessage.DeleteWarning.alertTitle, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: Z.AlertMessage.DeleteWarning.actionTitle, style: .destructive) { (action) in
            
            let databaseManager = MainViewController.databaseManager
            let savedDataList = databaseManager.listOfSavedFileNames()
            let dataID = savedDataList[self.currentPage]
            
            // Delete data in file system, database and refresh the imageArray
            databaseManager.deleteData(id: dataID)
            
            // Remove buffer view in memory buffer array
            self.bufferImageArray.remove(at: self.currentPage)
            
            // Animate the scroll view
            self.scrollAndRemoveImageView()
        }
        
        let cancelAction = UIAlertAction(title: Z.AlertMessage.DeleteWarning.cancelTitle, style: .cancel) { (action) in
            return
        }
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Stack View & Toolbar Preparation
    
    private func setToolbarStyle() {
        // Make toolbar's background transparent
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }
    
    //MARK: - Background Color
    
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
