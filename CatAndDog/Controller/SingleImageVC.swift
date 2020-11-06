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
    
    var selectedIndex: Int?
    var imageScrollView: ImageScrollView!
    var currentPage: Int {
        Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    var previousPage: Int?
    var anchorPosition: CGPoint?
    let databaseManager = DatabaseManager()
    
    // TEST
    var fullImages = DatabaseManager.thumbImages
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpToolbar()
        self.scrollView.delegate = self
        
        // Prevent scrollView from responding to two-finger panning events
        disableTwoFingerScroll()
        
        removeImageView(at: 0) // Remove the template imageView
        addImagesToStackView()
        
        // Scroll to user selected image at the collection view controller
        scrollToSelectedView()
        
        /// TEST AREA
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Save the center position of the stackView's first arranged subview after the view is loaded
        self.anchorPosition = stackView.arrangedSubviews[0].center
    }
    
    //MARK: - Image Zooming Scale Control
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.previousPage = self.currentPage
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard self.previousPage != nil else { return }
        if self.currentPage != self.previousPage {
            let previousImage = self.stackView.arrangedSubviews[self.previousPage!] as! ImageScrollView
            previousImage.zoomScale = previousImage.minimumZoomScale
        }
    }
    
    //MARK: - Stack View & Toolbar Preparation
    
    private func setUpToolbar() {
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
    
    private func removeImageView(at index: Int) {
        let viewToDelete = stackView.arrangedSubviews[index]
        stackView.removeArrangedSubview(viewToDelete)
        viewToDelete.removeFromSuperview()
    }
    
    private func addImagesToStackView() {
        for image in fullImages {
            self.imageScrollView = ImageScrollView(frame: view.bounds)
            self.imageScrollView.set(image: image)
            stackView.addArrangedSubview(self.imageScrollView)
            self.imageScrollView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor).isActive = true
            self.imageScrollView.heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor).isActive = true
        }
    }
    
    private func scrollToSelectedView() {
        DispatchQueue.main.async {
            guard let pageNumber = self.selectedIndex else { return }
            self.scrollView.contentOffset = CGPoint(x: CGFloat(pageNumber) * self.scrollView.frame.width, y: 0)
        }
    }
    
    private func disableTwoFingerScroll() {
        let twoFingerPan = UIPanGestureRecognizer()
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        self.scrollView.addGestureRecognizer(twoFingerPan)
    }
    
    //MARK: - Toolbar Button Methods
    
    @objc func shareButtonPressed() {
        let imageToShare = fullImages[currentPage]
        
        // present activity controller
        let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        self.present(activityController, animated: true)
    }
    
    @objc func deleteButtonPressed() {
        let alert = UIAlertController(title: "This action can not be reverted.", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Image", style: .destructive) { (action) in
            
            let savedImageIDs = self.databaseManager.listOfFileNames()
            let reversedIDIndex = (self.fullImages.count - 1) - self.currentPage // Find the data index from the reversed image array
            let dataToDeleteID = savedImageIDs[reversedIDIndex]
            
            // Delete data in file system and database and refresh the imageArray
            self.databaseManager.deleteData(id: dataToDeleteID)
            
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
    
    /// Stack view will be scrolled to the next page if the deleted view is not the last one in the stack view
    private func scrollAndRemoveImageView() {
        let originalPage = currentPage
        var pageToScroll: Int?
        let subviewCount = stackView.arrangedSubviews.count
        if subviewCount > 1 {
            if currentPage != subviewCount - 1 { // Scroll to right if current page is NOT the last one in the stackview
                pageToScroll = currentPage + 1
            } else { // Scroll to left if current page is the last one in the stackview
                pageToScroll = currentPage - 1
            }
        } else if subviewCount == 1 { // Only one subview is in the stackview
            // Go back to collection view
            self.navigationController?.popViewController(animated: true)
        }
        
        // Animate scrolling and remove the subview
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
                    // Remove imageview from the stackview
                    self.removeImageView(at: originalPage)
                    
                    // Reset scroll view's content offset to the previous position if the removed image view was at the left side of the scroll view
                    if pageToScroll == originalPage + 1 {
                        self.scrollView.contentOffset = CGPoint(x: CGFloat(originalPage) * self.scrollView.frame.width, y: 0)
                    }
                }
            }
        }
    }
    
}
