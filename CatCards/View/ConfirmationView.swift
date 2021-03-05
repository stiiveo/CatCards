//
//  ConfirmationView.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/5.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//
// A customized view which can be used to display confirmation icon onto the center of the designated view.

import UIKit

class ConfirmationView {
    let parentView: UIView
    let confirmImage: UIImage
    let confirmView: UIImageView
    
    init(parentView: UIView, confirmImage: UIImage) {
        self.parentView = parentView
        self.confirmImage = confirmImage
        confirmView = UIImageView(image: confirmImage)
        
        addImageToParentView()
    }
    
    /// Add confirmation view to the parent view, set up its size and position it to the center of the parent view.
    private func addImageToParentView() {
        parentView.addSubview(confirmView)
        confirmView.translatesAutoresizingMaskIntoConstraints = false
        
        // Size of the feedback view
        // Note: In order to make corner radius work, width and height must be the same
        // Limit the maximum size to 100 x 100
        let confirmViewSize = CGSize(
            width: min(100, parentView.frame.width * 0.3),
            height: min(100, parentView.frame.width * 0.3))
        
        NSLayoutConstraint.activate([
            confirmView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            confirmView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            confirmView.widthAnchor.constraint(equalToConstant: confirmViewSize.width),
            confirmView.heightAnchor.constraint(equalToConstant: confirmViewSize.height)
        ])
    }
    
    /// Show the confirmation image to the designated parent view with customizable delay and duration.
    /// Using this method after the customized confirmation view is initialized.
    /// It's suggested to use this method when a visual message displaying to the user is appropriate, e.g. the image is downloaded successfully.
    ///
    /// - Parameters:
    ///   - delayDuration: How long the animation is delayed before being started.
    ///   - duration: The duration of the animation, from the appearence to dismissal of the confirmation view.
    func startAnimation(withDelay delayDuration: Double?, duration: Double) {
        let v = self.confirmView
        
        // Initiate animations
        let totalDuration = duration
        let introAnimator = UIViewPropertyAnimator(duration: totalDuration / 4, curve: .linear) {
            v.alpha = 1.0
            v.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
        let normalStateAnimator = UIViewPropertyAnimator(duration: totalDuration / 4, curve: .linear) {
            v.transform = .identity
        }
        let dismissAnimator = UIViewPropertyAnimator(duration: totalDuration / 2, curve: .linear) {
            v.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            v.alpha = 0
        }
        
        // Sequence of animations
        introAnimator.addCompletion { _ in
            normalStateAnimator.startAnimation()
        }
        normalStateAnimator.addCompletion { _ in
            dismissAnimator.startAnimation(afterDelay: 0.5)
        }
        dismissAnimator.addCompletion { _ in
            v.removeFromSuperview()
        }
        
        introAnimator.startAnimation(afterDelay: delayDuration == nil ? 0 : delayDuration!)
    }
}
