//
//  CatViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CatViewController: UIViewController, CatDataManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!

    var catDataManager = CatDataManager()
    var arrayIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // download 5 new images into imageArray
        startFetchImage(initialRequest: true)
    }
    
    private func startFetchImage(initialRequest: Bool) {
        // first time loading image data
        if initialRequest {
            refreshButton.isEnabled = false
            refreshButton.tintColor = UIColor.systemGray
            indicator.startAnimating()
            catDataManager.performRequest(imageDownloadNumber: 3)
        } else {
            catDataManager.performRequest(imageDownloadNumber: 1)
            
        }
        
    }

    @IBAction func refreshBtnPressed(_ sender: UIButton) {
        startFetchImage(initialRequest: false)
        
        // make sure there's new image in imageArray ready to be loaded
        if catDataManager.catImages.imageArray.count > 1 {
            arrayIndex += 1
            imageView.image = catDataManager.catImages.imageArray[arrayIndex]
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
            self.imageView.image = firstDownloadedImage
            
            // update UI components
            self.indicator.stopAnimating()
            self.refreshButton.isEnabled = true
            self.refreshButton.tintColor = UIColor.systemBlue
        }
    }
    
    @IBAction func cardPanGesture(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view else { return }
        
        // point between the current pan and original location
        let point = sender.translation(in: view)
        // distance between card's and view's x axis center point
        let xFromCenter = card.center.x - view.center.x
        let viewWidth = view.frame.width
        // Angle 35º ≈ 0.61 radian
        let cardRotationRadian = 0.61 * xFromCenter / (viewWidth / 2)
        
        // card move to where the user's finger is
        card.center = CGPoint(x: view.center.x + point.x, y: view.center.y + point.y)
        // card's opacity increase when it approaches the side edge of the screen
        card.alpha = 1.5 - (abs(xFromCenter) / view.center.x)
        // card's rotation increase when it approaches the side edge of the screen
        card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
        
        // when user's finger left the screen
        if sender.state == .ended {
            // if card is moved to the left edge of the screen
            if card.center.x < viewWidth / 5 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x - 200, y: card.center.y)
//                    card.alpha = 0
                }
                
                // test use
                UIView.animate(withDuration: 0.2) {
                    card.center = self.view.center
                    card.alpha = 1.0
                    card.transform = CGAffineTransform(rotationAngle: 0)
                }
                
            // if card is moved to the right edge of the screen
            } else if card.center.x > viewWidth * 4/5 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x + 200, y: card.center.y)
//                    card.alpha = 0
                }
                
                // test use
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
                    card.transform = CGAffineTransform(rotationAngle: 0)
                }
            }
            
            
        }
    }
}

