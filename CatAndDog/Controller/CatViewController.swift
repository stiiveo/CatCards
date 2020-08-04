//
//  CatViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CatViewController: UIViewController, CatDataManagerDelegate {
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    var catDataManager = CatDataManager()
    
    let cardView = UIView()
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true
        
        // download designated number of new images into imageArray
        startFetchImage(initialRequest: true)
        
        // add UIPanGestureRecognizer to cardView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureHandler))
        cardView.addGestureRecognizer(panGesture)

        // add new card view and imageView
        self.view.addSubview(self.cardView)
        self.cardView.addSubview(self.imageView)
        self.addCardViewConstraint(cardView: self.cardView)
        self.addImageViewConstraint(imageView: self.imageView, contraintTo: self.cardView)
    }

    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard let image = catDataManager.catImages.imageArray.first else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }
    
    // add constraints to cardView
    private func addCardViewConstraint(cardView: UIView) {
        let viewMargins = self.view.layoutMarginsGuide
        
        cardView.leadingAnchor.constraint(equalTo: viewMargins.leadingAnchor, constant: K.CardView.Constraint.leading).isActive = true
        cardView.trailingAnchor.constraint(equalTo: viewMargins.trailingAnchor, constant: K.CardView.Constraint.trailing).isActive = true
        cardView.centerYAnchor.constraint(equalTo: viewMargins.centerYAnchor, constant: -K.ToolBar.height).isActive = true
        cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: K.CardView.Constraint.heightToWidthRatio).isActive = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        // style
        cardView.layer.cornerRadius = K.CardView.Style.cornerRadius
        cardView.layer.borderWidth = K.CardView.Style.borderWidth
        cardView.backgroundColor = K.CardView.Style.backgroundColor
    }
    
    // add constraints to imageView
    private func addImageViewConstraint(imageView: UIImageView, contraintTo cardView: UIView) {
        imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: K.ImageView.Constraint.top).isActive = true
        imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: K.ImageView.Constraint.leading).isActive = true
        imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: K.ImageView.Constraint.trailing).isActive = true
        imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: K.ImageView.Constraint.bottom).isActive = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // style
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
    }
    
    private func startFetchImage(initialRequest: Bool) {
        // first time loading image data
        if initialRequest {
            catDataManager.performRequest(imageDownloadNumber: 3)
        } else {
            catDataManager.performRequest(imageDownloadNumber: 1)
        }
    }

    private func updateCatImage() {
        startFetchImage(initialRequest: false)
        var arrayIndex = 0
        
        // make sure there's new image in imageArray ready to be loaded
        if catDataManager.catImages.imageArray.count > 1 {
            arrayIndex += 1
            imageView.image = catDataManager.catImages.imageArray[arrayIndex]
            catDataManager.catImages.imageArray.removeFirst()
            arrayIndex = 0
        }
    }

    internal func dataDidFetch() {
        // update image and UI components
        let imageArray = catDataManager.catImages.imageArray
        DispatchQueue.main.async {
            // update image
            guard let firstImage = imageArray.first else { print("Fail to get image"); return }
            self.imageView.image = firstImage
        }
    }
    
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view else { return }
        let viewWidth = view.frame.width
        let cardDefaultPosition = CGPoint(x: self.view.center.x, y: self.view.center.y - K.ToolBar.height / 2)
        
        // point between the current pan and original location
        let fingerMovement = sender.translation(in: view)
        
        // amount of offset the card moved from its original position
        let xAxisPanOffset = card.center.x - cardDefaultPosition.x
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let cardRotationRadian = (rotationAtMax / 4) * (xAxisPanOffset / (viewWidth / 3))
        
        // card move to where the user's finger is
        card.center = CGPoint(x: cardDefaultPosition.x + fingerMovement.x, y: cardDefaultPosition.y + fingerMovement.y)
        
        // card's rotation increase when it approaches the side edge of the screen
        card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
        
        // when user's finger left the screen
        if sender.state == .ended {
            // if card is moved to the left edge of the screen
            if card.center.x < viewWidth / 4 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x - 200, y: card.center.y)
                    
                    // (TEST USE) update image
                    self.updateCatImage()
                }
                
                // (TEST USE)
                UIView.animate(withDuration: 0.2) {
                    card.center = cardDefaultPosition
                    card.transform = CGAffineTransform.identity
                }
                
            // if card is moved to the right edge of the screen
            } else if card.center.x > viewWidth * 3/4 {
                UIView.animate(withDuration: 0.2) {
//                    card.center = CGPoint(x: card.center.x + 200, y: card.center.y)
                    
                    // (TEST USE) update image
                    self.updateCatImage()
                }
                
                // (TEST USE)
                UIView.animate(withDuration: 0.2) {
                    card.center = cardDefaultPosition
                    card.transform = CGAffineTransform.identity
                }
                
            } else {
                // animate card back to origianl position, opacity and rotation state
                UIView.animate(withDuration: 0.2) {
                    card.center = cardDefaultPosition
                    card.alpha = 1.0
                    card.transform = CGAffineTransform.identity
                }
            }
            
            
        }
    }
    
    func errorDidOccur() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Cannot connect to the Internet",
                message: "Signal from Cat Planet is too weak.\n Please check your antenna. 📡",
                preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(settingsAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
}

