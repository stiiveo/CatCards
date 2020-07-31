//
//  CatViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CatViewController: UIViewController, CatDataManagerDelegate {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!

    var catDataManager = CatDataManager()
    var arrayIndex = 0
    
    let firstCardView: UIView = {
        let myView = UIView()
        myView.translatesAutoresizingMaskIntoConstraints = false
        myView.layer.cornerRadius = K.CardViewStyle.cornerRadius
        myView.layer.borderWidth = K.CardViewStyle.borderWidth
        
        return myView
    }()
    
    let firstImageView: UIImageView = {
        let myImageView = UIImageView()
        myImageView.translatesAutoresizingMaskIntoConstraints = false
        
        /** contentMode's value cannot be set to .scaleAspectFill
            imageView's contraints will be ignored for unknown reason
        */
        myImageView.contentMode = .scaleAspectFit
        return myImageView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // download designated number of new images into imageArray
        startFetchImage(initialRequest: true)
        
        // add new card view and imageView
        self.view.addSubview(firstCardView)
        firstCardView.addSubview(firstImageView)
        
        // add constraints to views added
        addCardViewConstraint(cardView: firstCardView)
        addImageViewConstraint(imageView: firstImageView, contraintTo: firstCardView)

        // add UIPanGestureRecognizer to firstCardView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureHandler))
        firstCardView.addGestureRecognizer(panGesture)
    }

    // add constraints to cardView
    func addCardViewConstraint(cardView: UIView) {
        let margins = self.view.layoutMarginsGuide
        cardView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: K.CardViewConstraint.leading).isActive = true
        cardView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: K.CardViewConstraint.trailing).isActive = true
        cardView.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        cardView.heightAnchor.constraint(equalTo: margins.heightAnchor, multiplier: K.CardViewConstraint.heightMultiplier).isActive = true
        
        cardView.backgroundColor = K.CardViewStyle.backgroundColor
    }
    
    // add constraints to imageView
    func addImageViewConstraint(imageView: UIImageView, contraintTo cardView: UIView) {
        imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: K.ImageViewConstraint.top).isActive = true
        imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: K.ImageViewConstraint.leading).isActive = true
        imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: K.ImageViewConstraint.trailing).isActive = true
        imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: K.ImageViewConstraint.bottom).isActive = true
    }
    
    private func startFetchImage(initialRequest: Bool) {
        // first time loading image data
        if initialRequest {
//            indicator.startAnimating()
            catDataManager.performRequest(imageDownloadNumber: 3)
        } else {
            catDataManager.performRequest(imageDownloadNumber: 1)
            
        }
        
    }

    private func updateCatImage() {
        startFetchImage(initialRequest: false)
        
        // make sure there's new image in imageArray ready to be loaded
        if catDataManager.catImages.imageArray.count > 1 {
            arrayIndex += 1
            firstImageView.image = catDataManager.catImages.imageArray[arrayIndex]
            catDataManager.catImages.imageArray.removeFirst()
            arrayIndex = 0
        }
        
    }

    func dataDidFetch() {
        // update image and UI components
        let imageArray = catDataManager.catImages.imageArray
        DispatchQueue.main.async {
            
            // update image
            guard let firstDownloadedImage = imageArray.first else { print("Fail to get image"); return }
            self.firstImageView.image = firstDownloadedImage
            
            // update UI components
//            self.indicator.stopAnimating()
        }
    }
    
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view else { return }
        let viewWidth = view.frame.width
        let viewXAxisCenterPoint = view.center.x
        
        // point between the current pan and original location
        let fingerMovement = sender.translation(in: view)
        
        // distance between card's and view's x axis center point
        let xAxisPanOffset = card.center.x - viewXAxisCenterPoint
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let cardRotationRadian = (rotationAtMax / 4) * (xAxisPanOffset / (viewWidth / 3))
        
        // card move to where the user's finger is
        card.center = CGPoint(x: viewXAxisCenterPoint + fingerMovement.x, y: view.center.y + fingerMovement.y)
        // card's opacity increase when it approaches the side edge of the screen
//        card.alpha = 1.5 - (abs(xAxisPanOffset) / viewXAxisCenterPoint)
        // card's rotation increase when it approaches the side edge of the screen
        card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
        
        // when user's finger left the screen
        if sender.state == .ended {
            // if card is moved to the left edge of the screen
            if card.center.x < viewWidth / 4 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x - 200, y: card.center.y)
//                    card.alpha = 0
                    
                    // (TEST USE) update image
                    self.updateCatImage()
                }
                
                // (TEST USE)
                UIView.animate(withDuration: 0.2) {
                    card.center = self.view.center
                    card.alpha = 1.0
                    card.transform = CGAffineTransform(rotationAngle: 0)
                }
                
            // if card is moved to the right edge of the screen
            } else if card.center.x > viewWidth * 3/4 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x + 200, y: card.center.y)
//                    card.alpha = 0
                    
                    // (TEST USE) update image
                    self.updateCatImage()
                }
                
                // (TEST USE)
                UIView.animate(withDuration: 0.2) {
                    card.center = self.view.center
                    card.alpha = 1.0
                    card.transform = CGAffineTransform(rotationAngle: 0)
                }
                
            } else {
                // animate card back to origianl position, opacity and rotation state
                UIView.animate(withDuration: 0.2) {
                    card.center = self.view.center
                    card.alpha = 1.0
                    card.transform = CGAffineTransform.identity
                }
            }
            
            
        }
    }
}

