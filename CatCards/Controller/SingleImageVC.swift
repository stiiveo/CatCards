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
    private let dbManager = DBManager.shared
    private let backgroundLayer = CAGradientLayer()
    private var bufferImageArray: [ImageScrollView] = []
    private let bufferImageNumber: Int = K.Data.prefetchNumberOfImageAtEachSide
    private let defaultCacheImage = K.Image.defaultCacheImage
    private let hapticManager = HapticManager()
    private var previousPage: Int = 0
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
        
        // Prevent scrollView from responding to two-finger panning events.
        attachPanGestureRecognizer()
        
        // Remove the template imageView set up in storyboard interface
        removeImageView(atPage: 0)
        
        // Set up background layer's color and add it to the view.
        backgroundLayer.frame = view.bounds
        setBackgroundColor()
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setToolbarStyle()
        
        // Create imageView cache.
        initiateImageBufferArray()
        
        // Populate cache array with default imageViews.
        loadDefaultImageView()
        loadImagesToStackView(atIndex: selectedCellIndex)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            // Update background layer's frame
            self.backgroundLayer.frame = self.view.bounds
            
            /* By reloading the images again, each ImageScrollView's frame will be updated
             according to the frame of the view it's going to be.
             */
            self.loadImagesToStackView(atIndex: self.currentPage)
        }, completion: nil)
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
    
    private func loadImagesToStackView(atIndex index: Int) {
        // Load images to selected imageView and nearby ones.
        let startIndex = selectedCellIndex - bufferImageNumber
        let endIndex = selectedCellIndex + bufferImageNumber
        
        for index in startIndex...endIndex {
            setImage(at: index)
        }
        // Scroll to show the user selected image.
        setScrollViewOffset(toIndex: index)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Save the index of scrollView's page before it's changed by the user.
        previousPage = currentPage
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    
    /// Dynamically load/unload images and control the total number of arranged subviews in the stackView to limit the memory usage.
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
        switch direction {
        case .forward:
            // Update imageView ahead of current page
            setImage(at: currentPage + bufferImageNumber)
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage - bufferImageNumber - 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.updateImageView(image: defaultCacheImage)
            }
        case .backward:
            // Update imageView before the current page
            setImage(at: currentPage - bufferImageNumber)
            
            // Reset image out of the buffer range
            let bufferToRemoveIndex = currentPage + bufferImageNumber + 1
            guard bufferToRemoveIndex >= 0 && bufferToRemoveIndex < bufferImageArray.count else { return }
            if let imageToReset = stackView.arrangedSubviews[bufferToRemoveIndex] as? ImageScrollView {
                imageToReset.updateImageView(image: defaultCacheImage)
            }
        }
    }
    
    /// Load image at designated index from local disk to memory buffer
    /// - Parameter index: Image's index number of the image buffer array
    private func setImage(at index: Int) {
        // Ensure index is within the bound of array
        guard 0 <= index && index < dbManager.imageFileURLs.count else { return }
        
        let imageFileURL = dbManager.imageFileURLs[index].image
        guard let imageAtDisk = UIImage(contentsOfFile: imageFileURL.path) else { return }
        bufferImageArray[index].updateImageView(image: imageAtDisk)
    }
    
    /*
     Create an `ImageScrollView` array with same item number as local saved image number
     and set each object's image property the default image defined in this class.
     */
    private func initiateImageBufferArray() {
        bufferImageArray = (1...dbManager.imageFileURLs.count).map { _ in
            let imageView = ImageScrollView(frame: view.bounds)
            imageView.updateImageView(image: defaultCacheImage)
            return imageView
        }
    }
    
    /// Load ImageScrollView objects from cached array of 'imageViews' into stackView
    private func loadDefaultImageView() {
        for index in 0...(dbManager.imageFileURLs.count - 1) {
            stackView.addArrangedSubview(bufferImageArray[index])
            bufferImageArray[index].widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor).isActive = true
            bufferImageArray[index].heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor).isActive = true
        }
    }
    
    //MARK: - ScrollView Behavior Setting
    
    private func setScrollViewOffset(toIndex index: Int) {
        DispatchQueue.main.async {
            let frameWidth = self.scrollView.frame.width
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(index) * frameWidth, y: 0), animated: false)
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
                // Remove imageView from the stackView
                self.removeImageView(atPage: originalPage)
                
                // Compensate the reduced number of arranged stackView if stack view is scrolled to the next page
                if pageToScroll == originalPage + 1 {
                    self.scrollView.contentOffset = CGPoint(x: CGFloat(originalPage) * self.scrollView.frame.width, y: 0)
                    
                    // After reverting to original page, the 'auto buffer updating' method will move the buffer image (2 images after the current image) out of buffer range, which causes it to be reset and not being updated when user scrolls to the next page.
                    // Therefore, it's neccesary to update the image which was reset due to the compensation of page number change.
                    self.setImage(at: originalPage + self.bufferImageNumber)
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
        let imageFileURLs = dbManager.imageFileURLs
        guard currentPage >= 0 && currentPage < imageFileURLs.count else { return }
        
        hapticManager.prepareImpactGenerator(style: .soft)
        let imageURL = dbManager.imageFileURLs[currentPage].image
        let activityVC = UIActivityViewController(activityItems: [imageURL], applicationActivities: nil)
        
        // Set up Popover Presentation Controller's barButtonItem for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.barButtonItem = sender
        }
        
        self.present(activityVC, animated: true)
        hapticManager.impactHaptic?.impactOccurred()
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        hapticManager.prepareNotificationGenerator()
        hapticManager.notificationHaptic?.notificationOccurred(.warning)
        
        let alert = UIAlertController(title: Z.AlertMessage.DeleteWarning.alertTitle, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: Z.AlertMessage.DeleteWarning.actionTitle, style: .destructive) { (action) in
            
            let databaseManager = DBManager.shared
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
        
        // Set up Popover Presentation Controller's barButtonItem for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.barButtonItem = sender
        }
        
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
