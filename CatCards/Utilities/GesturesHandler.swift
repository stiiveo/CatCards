//
//  GesturesHandler.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/5/4.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

protocol HomeVCDelegate: UIViewController, UIGestureRecognizerDelegate {
    var currentCard: Card? { get }
    var nextCard: Card? { get }
    var pointer: Int { get set }
    var cardIsBeingPanned: Bool { get set }
    var onboardCompleted: Bool { get set }
    var collectionButton: UIBarButtonItem! { get set }
    var shadingLayer: UIView! { get set }
    var cardArray: [Int: Card] { get set }
    var maxPointerReached: Int { get set }
    var viewCount: Int { get set }
    func addCardToView(_ card: Card, atBottom: Bool)
    func sendAPIRequest(numberOfRequests: Int)
    func refreshButtonState()
    func clearCacheData()
}

class GesturesHandler {
    
    unowned var delegate: HomeVCDelegate
    unowned var superview: UIView
    
    init(delegate: HomeVCDelegate, superview: UIView) {
        self.delegate = delegate
        self.superview = superview
    }
    
    private var panGestureRecognizer: UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        pan.delegate = delegate
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        return pan
    }
    
    private var pinchGestureRecognizer: UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler))
        pinch.delegate = delegate
        return pinch
    }
    
    private var twoFingerPanGestureRecognizer: UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(twoFingerPanHandler))
        pan.delegate = delegate
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        return pan
    }
    
    private var tapGestureRecognizer: UITapGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        tap.delegate = delegate
        return tap
    }
    
    private enum TouchSide {
        case upper, lower
    }
    
    private var firstFingerLocation: TouchSide?
    private var cardTransform: CGAffineTransform = .identity
    
}

// MARK: - Gestures Handlers

extension GesturesHandler {
    
    // Pan Gesture Handler
    
    @objc private func panHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        let viewHalfWidth = card.frame.width / 2
        
        // Detect onto which side (upper or lower) of the card is the user's finger placed.
        let fingerPosition = sender.location(in: sender.view)
        let side: TouchSide = fingerPosition.y < card.frame.midY ? .upper : .lower
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
            let minTravelDistance = card.frame.width // minimum travel distance of the card
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
    
    // Two–finger Pan Gesture Handler
    
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
    
    // Pinch Gesture Handler
    
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
            delegate.shadingLayer.alpha = min(maxOpacity, card.transform.a - 1.0)
            
        case .ended, .cancelled, .failed:
            // Reset card's size
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [.curveEaseOut]) {
                card.transform = .identity
                self.delegate.shadingLayer.alpha = 0
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
    
    // Tap Gesture Handler
    
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

// MARK: - Attaching & Animation

extension GesturesHandler {
    
    /// Attach all gesture recognizers to the designated card.
    /// - Parameter card: The card to which the gesture recognizers are attached.
    func addGestureRecognizers(to card: Card) {
        card.addGestureRecognizer(panGestureRecognizer)
        card.addGestureRecognizer(pinchGestureRecognizer)
        card.addGestureRecognizer(twoFingerPanGestureRecognizer)
        card.addGestureRecognizer(tapGestureRecognizer)
        
        // Save references
        card.panGR = panGestureRecognizer
        card.pinchGR = pinchGestureRecognizer
        card.twoFingerPanGR = twoFingerPanGestureRecognizer
        card.tapGR = tapGestureRecognizer
    }
    
    func resetTransform() {
        cardTransform = .identity
    }
    
    // Animation Methods
    
    /// Dismiss the card and reset the current card's size if there's any.
    /// - Parameters:
    ///   - card: The card to be dismissed.
    ///   - deltaX: X–axis delta applied to the card.
    ///   - deltaY: Y–axis delta applied to the card.
    func dismissCardWithVelocity(_ card: Card, deltaX: CGFloat, deltaY: CGFloat) {
        
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
    
}
