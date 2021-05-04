//
//  GesturesHandler.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/5/4.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

protocol CustomViewController: UIGestureRecognizerDelegate {
    var view: UIView { get set }
    var currentCard: Card? { get }
    var nextCard: Card? { get }
    var pointer: Int { get set }
    var cardIsBeingPanned: Bool { get set }
    var onboardCompleted: Bool { get set }
    var collectionButton: UIBarButtonItem { get set }
    var shadeLayer: UIView { get set }
    var cardArray: [Int: Card] { get set }
    var maxPointerReached: Int { get set }
    var viewCount: Int { get set }
    func addCardToView(_ card: Card, atBottom: Bool)
    func sendAPIRequest(numberOfRequests: Int)
    func refreshButtonState()
    func clearCacheData()
}

class GesturesHandler {
    
    var delegate: CustomViewController
    var superview: UIView
    
    private enum Side {
        case upper, lower
    }
    
    private var firstFingerLocation: Side!
    private var cardTransform: CGAffineTransform = .identity
    
    @objc var panHandler: UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: delegate, action: #selector(getter: self.panHandler))
        pan.delegate = delegate
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        return pan
    }
    
    @objc var pinchHandler: UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer(target: delegate, action: #selector(getter: self.pinchHandler))
        pinch.delegate = delegate
        return pinch
    }
    
    @objc var twoFingerPanHandler: UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(getter: self.twoFingerPanHandler))
        pan.delegate = delegate
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        return pan
    }
    
    @objc var tapHandler: UITapGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self, action: #selector(getter: self.tapHandler))
        tap.delegate = delegate
        return tap
    }
    
    init(delegate: CustomViewController, superview: UIView) {
        self.delegate = delegate
        self.superview = superview
    }
    
}

// MARK: - Gestures Handlers

extension GesturesHandler {
    
    @objc private func panHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        let viewHalfWidth = card.frame.width / 2
        
        // Detect onto which side (upper or lower) of the card is the user's finger placed.
        let fingerPosition = sender.location(in: sender.view)
        let side: Side = fingerPosition.y < card.frame.midY ? .upper : .lower
        firstFingerLocation = (firstFingerLocation == nil) ? side : firstFingerLocation
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisOffset = card.transform.tx
        let yAxisOffset = card.transform.ty
        let maxRotation: CGFloat = 1.0 / 6 // 1.0 Radian = 180º | 180° / 6 = 30°
        // Card reaches its maximum rotation degree when its y–axis reaches the edge of the view.
        let rotationDegree = maxRotation * (xAxisOffset / viewHalfWidth)
        
        // Card's rotation direction is based on the finger position on the card
        let cardRotationRadian = (firstFingerLocation == .upper) ? rotationDegree : -rotationDegree
        let velocity = sender.velocity(in: superview) // points per second
        
        // Card's offset of x and y position
        let cardOffset = CGPoint(x: xAxisOffset, y: yAxisOffset)
        // Distance by which the card is offset by the user.
        let panDistance = hypot(cardOffset.x, cardOffset.y)
        
        switch sender.state {
        case .began:
            delegate.cardIsBeingPanned = true
        case .changed:
            /*
             Sync the card position's offset with the offset amount applied by the user.
             Increase the card's rotation degrees as it approaches either side of the screen.
             */
            let t = sender.translation(in: superview)
            let translation = CGAffineTransform(translationX: t.x, y: t.y)
            let rotation = CGAffineTransform(rotationAngle: cardRotationRadian)
            cardTransform = translation.concatenating(rotation)
            card.transform = cardTransform
            
            // Determine next card's transform based on current card's travel distance
            let distance = (panDistance <= viewHalfWidth) ? (panDistance / viewHalfWidth) : 1
            let defaultScale = K.Card.SizeScale.standby
            delegate.nextCard?.transform = CGAffineTransform(
                scaleX: defaultScale + (distance * (1 - defaultScale)),
                y: defaultScale + (distance * (1 - defaultScale))
            )
            
        // When user's finger left the screen.
        case .ended, .cancelled, .failed:
            firstFingerLocation = nil // Reset first finger location
            let minTravelDistance = card.frame.height // minimum travel distance of the card
            let minDragDistance = viewHalfWidth // minimum dragging distance of the card
            let vector = CGPoint(x: velocity.x / 2, y: velocity.y / 2)
            let vectorDistance = hypot(vector.x, vector.y)
            /*
             Card dismissing threshold A:
             The projected travel distance is greater than or equals minimum distance.
             */
            if vectorDistance >= minTravelDistance {
                delegate.pointer += 1
                dismissCardWithVelocity(card, deltaX: vector.x, deltaY: vector.y)
                self.resetTransform()
            }
            /*
             Card dismissing threshold B:
             The projected travel distance is less than the minimum travel distance
             BUT the distance of card being dragged is greater than distance threshold.
             */
            else if vectorDistance < minTravelDistance && panDistance >= minDragDistance {
                let distanceDelta = minTravelDistance / panDistance
                let minimumDelta = CGPoint(x: cardOffset.x * distanceDelta,
                                           y: cardOffset.y * distanceDelta)
                delegate.pointer += 1
                dismissCardWithVelocity(card, deltaX: minimumDelta.x, deltaY: minimumDelta.y)
                self.resetTransform()
            }
            
            // Reset card's position and rotation.
            else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.1, options: [.curveEaseOut, .allowUserInteraction]) {
                    card.transform = .identity
                    self.delegate.nextCard?.setSize(status: .standby)
                } completion: { _ in
                    self.resetTransform()
                    self.delegate.cardIsBeingPanned = false
                }
            }
        default:
            break
        }
    }
    
    /// What happens when user uses two finger to pan the card.
    /// - Parameter sender: A discrete gesture recognizer that interprets panning gestures.
    @objc private func twoFingerPanHandler(sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        switch sender.state {
        case .changed:
            // Card's moved to where the user's fingers are
            let translation = sender.translation(in: superview)
            let scaledTranslation = CGPoint(x: translation.x / card.transform.a,
                                            y: translation.y / card.transform.d)
            card.transform = cardTransform.translatedBy(x: scaledTranslation.x, y: scaledTranslation.y)
            
        case .ended, .cancelled, .failed:
            // Move card back to original position
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.1, options: [.curveEaseOut, .allowUserInteraction]) {
                card.transform = .identity
            }
        default:
            break
        }
    }
    
    /// What happens when user pinches the card with 2 fingers.
    /// - Parameter sender: A discrete gesture recognizer that interprets pinching gestures involving two touches.
    @objc private func pinchHandler(sender: UIPinchGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        switch sender.state {
        case .began:
            // Hide navBar button
            if delegate.onboardCompleted {
                delegate.collectionButton.tintColor = .clear
            }
            
            // Hide card's trivia overlay
            if HomeVC.showOverlay {
                card.hideTriviaOverlay()
            }
            
        case .changed:
            // Coordinate of the pinch center where the view's center is (0, 0)
            let pinchCenter = CGPoint(
                x: sender.location(in: card).x - card.bounds.midX,
                y: sender.location(in: card).y - card.bounds.midY)
            
            // Card's size can only be scaled up.
            if card.transform.a >= 1 {
                // Move the card to the opposite point of the pinch center if the scale delta > 1, vice versa
                cardTransform = cardTransform.translatedBy(x: pinchCenter.x, y: pinchCenter.y).scaledBy(x: sender.scale, y: sender.scale).translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                card.transform = cardTransform
            }
            sender.scale = 1
            
            // Increase opacity of the overlay view as the card is enlarged
            let maxOpacity: CGFloat = 0.7 // max opacity of the shading layer
            delegate.shadeLayer.alpha = min(maxOpacity, card.transform.a - 1.0)
            
        case .ended, .cancelled, .failed:
            // Reset card's size
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [.curveEaseOut, .allowUserInteraction]) {
                card.transform = .identity
                self.delegate.shadeLayer.alpha = 0
            } completion: { _ in
                self.resetTransform()
                if self.delegate.onboardCompleted {
                    self.delegate.collectionButton.tintColor = K.Color.tintColor
                }
            }
            
            // Re-show trivia overlay if showOverlay is true
            if HomeVC.showOverlay == true {
                card.showTriviaOverlay()
            }
        default:
            break
        }
        
    }
    
    /// What happens when user taps on the card.
    /// - Parameter sender: A discrete gesture recognizer that interprets single or multiple taps.
    @objc private func tapHandler(sender: UITapGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        
        if sender.state == .ended {
            // Toggle every regular card's overlay.
            switch card.cardType {
            case .regular:
                HomeVC.showOverlay = !HomeVC.showOverlay
                for card in delegate.cardArray.values {
                    card.toggleOverlay()
                }
            case .onboard:
                // Only the third onboard card's overlay can be toggled.
                if card.index == 2 {
                    card.toggleOverlay()
                }
            }
        }
    }
    
    
}



// MARK: - Auxiliary Methods

extension GesturesHandler {
    
    /// Attach all gesturn recognizers to the designated card.
    /// - Parameter card: The card to which the gesture recognizers are attached.
    private func addGestureRecognizers(to view: Card) {
        view.addGestureRecognizer(panHandler)
        view.addGestureRecognizer(pinchHandler)
        view.addGestureRecognizer(twoFingerPanHandler)
        view.addGestureRecognizer(tapHandler)
        
        // Save references
        view.panGR = panHandler
        view.pinchGR = pinchHandler
        view.twoFingerPanGR = twoFingerPanHandler
        view.tapGR = tapHandler
    }
    
    private func resetTransform() {
        cardTransform = .identity
    }
    
    //MARK: - Animation Methods
    
    /// Dismiss the card and reset the current card's size if there's any.
    /// - Parameters:
    ///   - card: The card to be dismissed.
    ///   - deltaX: X–axis delta applied to the card.
    ///   - deltaY: Y–axis delta applied to the card.
    private func dismissCardWithVelocity(_ card: Card, deltaX: CGFloat, deltaY: CGFloat) {
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            card.transform = card.transform.translatedBy(x: deltaX, y: deltaY)
            self.delegate.currentCard?.transform = .identity
        } completion: { _ in
            card.removeFromSuperview()
            self.delegate.cardIsBeingPanned = false
            
            // Add the next card to the view if it's not nil.
            if self.delegate.nextCard != nil {
                self.delegate.addCardToView(self.delegate.nextCard!, atBottom: true)
            }
            
            // Fetch new data if the next card has not being displayed before.
            if self.delegate.pointer > self.delegate.maxPointerReached {
                self.delegate.sendAPIRequest(numberOfRequests: 1)
            }
            
            // Update the number of cards viewed by the user if onboard session is completed
            // and the current card has not been seen by the user before.
            if self.delegate.onboardCompleted && self.delegate.pointer > self.delegate.maxPointerReached {
                self.delegate.viewCount += 1
            }
            
            // Refresh the status of the toolbar's buttons.
            DispatchQueue.main.async {
                self.delegate.refreshButtonState()
            }
            
            // Clear the old card's cache data.
            self.delegate.clearCacheData()
        }
    }
    
    /// Lay out this view's subviews immediately, if layout updates are pending.
    private func updateLayout() {
        delegate.view.layoutIfNeeded()
    }
}
