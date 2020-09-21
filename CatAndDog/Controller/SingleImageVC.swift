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
    
    weak var panGesture: UIPanGestureRecognizer?
    weak var pinchGesture: UIPinchGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        removeTemplateImageView()
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
    
    private func removeTemplateImageView() {
        let templateImageView = stackView.arrangedSubviews[0]
        stackView.removeArrangedSubview(templateImageView)
        templateImageView.removeFromSuperview()
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
        present(activityController, animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
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

