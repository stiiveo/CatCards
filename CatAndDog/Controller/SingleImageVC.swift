//
//  SingleImageVC.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/9/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class SingleImageVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    var imageToShowIndex: Int?
    var currentPage: Int {
        Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
    var previousPage: Int?
    var anchorPosition: CGPoint?
    let databaseManager = DatabaseManager()
    
    weak var panGesture: UIPanGestureRecognizer?
    weak var pinchGesture: UIPinchGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        removeImageView(at: 0) // Remove the template imageView
        addImagesToStackView()
        
        // Make scrollView to scroll to the image the user selected at the previous view controller
        DispatchQueue.main.async {
            guard let pageNumber = self.imageToShowIndex else { return }
            self.scrollView.contentOffset = CGPoint(x: CGFloat(pageNumber) * self.scrollView.frame.width, y: 0)
        }
        
        // Stop scrollView from reacting to two-finger panning events
        disableTwoFingerScroll()
        
        // Attach pinch and pan gesture recognizer to the selected view
        let pinchGR = getPinchGestureRecognizer()
        let panGR = getPanGestureRecognizer()
        if let index = imageToShowIndex {
            attachPinchGestureRecognizer(recognizer: pinchGR, to: index)
            attachPanGestureRecognizer(recognizer: panGR, to: index)
        }
        
        /// TEST AREA
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Save the center position of the stackView's first arranged subview after the view is loaded
        self.anchorPosition = stackView.arrangedSubviews[0].center
    }
    
    private func removeImageView(at index: Int) {
        let viewToDelete = stackView.arrangedSubviews[index]
        stackView.removeArrangedSubview(viewToDelete)
        viewToDelete.removeFromSuperview()
    }
    
    private func addImagesToStackView() {
        for image in DatabaseManager.imageArray {
            let newImageView = UIImageView()
            newImageView.contentMode = .scaleAspectFit
            newImageView.image = image
            stackView.addArrangedSubview(newImageView)
            newImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
            newImageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true
        }
        
        // Enable each imageView's user interaction
        for imageView in stackView.arrangedSubviews {
            imageView.isUserInteractionEnabled = true
        }
    }
    
    private func disableTwoFingerScroll() {
        let twoFingerPan = UIPanGestureRecognizer()
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        scrollView.addGestureRecognizer(twoFingerPan)
        panGesture = twoFingerPan
    }
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        let imageToShare = DatabaseManager.imageArray[currentPage]
        
        // present activity controller
        let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        self.present(activityController, animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "This action can not be reverted.", message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Image", style: .destructive) { (action) in
            
            let favoriteIDs = self.databaseManager.listOfFileNames()
            let dataID = favoriteIDs[self.currentPage]
            
            // Delete data in file system and database and refresh the imageArray
            self.databaseManager.deleteData(id: dataID)
            
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
    
    private func attachPanGestureRecognizer(recognizer: UIPanGestureRecognizer, to index: Int) {
        stackView.arrangedSubviews[index].addGestureRecognizer(recognizer)
        panGesture = recognizer
    }
    
    private func attachPinchGestureRecognizer(recognizer: UIPinchGestureRecognizer, to index: Int) {
        stackView.arrangedSubviews[index].addGestureRecognizer(recognizer)
        // save the references of the gesture recognizers
        pinchGesture = recognizer
    }
    
    private func getPanGestureRecognizer() -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self
        panGesture = pan
        
        // Only 2-finger panning action can be recognized
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        
        return pan
    }
    
    private func getPinchGestureRecognizer() -> UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom))
        pinch.delegate = self
        pinchGesture = pinch
        return pinch
    }
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .changed:
                // Limit how much the view can be zoomed out
                if view.frame.width > view.bounds.width / 1.5 {
                    // coordinate of the pinch center where the view's center is (0, 0)
                    let pinchCenter = CGPoint(x: gesture.location(in: view).x - view.bounds.midX,
                                              y: gesture.location(in: view).y - view.bounds.midY)
                    let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                        .scaledBy(x: gesture.scale, y: gesture.scale)
                        .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                    view.transform = transform
                    gesture.scale = 1
                }
                
                UIView.animate(withDuration: 0.2) {
//                    self.scrollView.backgroundColor = .black
                }
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    view.transform = .identity
//                    self.scrollView.backgroundColor = .white
                })
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Current displayed imageView
        let currentView = stackView.arrangedSubviews[currentPage] as! UIImageView

        // Compute the anchor position of the current imageView
        guard let anchor = self.anchorPosition else { return }
        let currentViewAnchor = CGPoint(
            x: anchor.x + self.scrollView.frameLayoutGuide.layoutFrame.width * CGFloat(self.currentPage),
            y: anchor.y)
        
        if let view = gesture.view {
            switch gesture.state {
            case .changed:
                // The view can only be panned around when it's zoomed in
                if view.frame.width > view.bounds.width {
                    
                    
                    // Get the touch position
                    let translation = gesture.translation(in: currentView)
                    
                    // Edit the center of the target by adding the gesture position
                    let zoomRatio = view.frame.width / view.bounds.width
                    view.center = CGPoint(
                        x: currentView.center.x + translation.x * zoomRatio,
                        y: currentView.center.y + translation.y * zoomRatio
                    )
                    gesture.setTranslation(.zero, in: currentView)
                }
                
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the original state
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    view.center = currentViewAnchor
                })
            }
        }
    }
    
}

extension SingleImageVC: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        previousPage = currentPage
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if currentPage != previousPage {
            
            // remove gesture recognizer attached to the previous imageView
            if let oldIndex = previousPage, let pinchGR = pinchGesture, let panGR = panGesture {
                stackView.arrangedSubviews[oldIndex].removeGestureRecognizer(pinchGR)
                stackView.arrangedSubviews[oldIndex].removeGestureRecognizer(panGR)
            }
            
            // add new gesture recognizers to the current imageView
            let pinch = getPinchGestureRecognizer()
            let pan = getPanGestureRecognizer()
            attachPinchGestureRecognizer(recognizer: pinch, to: currentPage)
            attachPanGestureRecognizer(recognizer: pan, to: currentPage)
        }
    }
    
}

extension SingleImageVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

