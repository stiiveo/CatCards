//
//  FeedbackView.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/5.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//
// A customized view which can be used to display feedback image onto the center of the specified view.

import UIKit

final class FeedbackView {
    
    // MARK: - Properties
    
    private let superview: UIView
    private let image: UIImage
    private let feedbackView: UIImageView
    
    // MARK: - Init
    
    init(parentView: UIView, image: UIImage) {
        self.superview = parentView
        self.image = image
        feedbackView = UIImageView(image: image)
        addViewToParentView()
    }
    
    // MARK: - Private Methods
    
    /// Add feedback view to the parent view, set up its size and position it to the center of the parent view.
    private func addViewToParentView() {
        superview.addSubview(feedbackView)
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        
        /*
         Size of the feedback view
         Note: In order to make corner radius work, width and height must be the same.
         Maximum size is 100 by 100.
         */
        let confirmViewSize = CGSize(
            width: min(100, superview.frame.width * 0.3),
            height: min(100, superview.frame.width * 0.3))
        
        NSLayoutConstraint.activate([
            feedbackView.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            feedbackView.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            feedbackView.widthAnchor.constraint(equalToConstant: confirmViewSize.width),
            feedbackView.heightAnchor.constraint(equalToConstant: confirmViewSize.height)
        ])
    }
    
    // MARK: - Public Methods
    
    /// Show the feedback image to the designated parent view with customizable delay and duration.
    ///
    /// Use this method when a visual message displaying to the user is appropriate,
    /// e.g. the image is downloaded successfully.
    ///
    /// - Parameters:
    ///   - delayDuration: How long the animation is delayed before being started.
    ///   - duration: The duration of the animation, from the appearance to dismissal of the confirmation view.
    func startAnimation(withDelay delayDuration: Double, duration: Double) {
        let feedbackView = self.feedbackView
        
        // Create animations
        let totalDuration = duration
        let introAnimator = UIViewPropertyAnimator(duration: totalDuration / 4, curve: .linear) {
            feedbackView.alpha = 1.0
            feedbackView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
        let normalStateAnimator = UIViewPropertyAnimator(duration: totalDuration / 4, curve: .linear) {
            feedbackView.transform = .identity
        }
        let dismissAnimator = UIViewPropertyAnimator(duration: totalDuration / 2, curve: .linear) {
            feedbackView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            feedbackView.alpha = 0
        }
        
        // Sequence of animations
        introAnimator.addCompletion { _ in
            normalStateAnimator.startAnimation()
        }
        normalStateAnimator.addCompletion { _ in
            dismissAnimator.startAnimation(afterDelay: 0.5)
        }
        dismissAnimator.addCompletion { _ in
            feedbackView.removeFromSuperview()
        }
        
        introAnimator.startAnimation(afterDelay: delayDuration)
    }
}
