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
    
    let cardView1 = UIView()
    let cardView2 = UIView()
    let imageView1 = UIImageView()
    let imageView2 = UIImageView()
    var cardViewCenterPosition: CGPoint?
    var imageIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // define toolBar's height
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true
        
        // download designated number of new images into imageArray
        startFetchImage(initialRequest: true)

        // create UIView, ImageView and constraints
        view.addSubview(cardView1)
        view.insertSubview(cardView2, belowSubview: cardView1)
        cardView1.addSubview(imageView1)
        cardView2.addSubview(imageView2)
        
        addCardViewConstraint(cardView: cardView1)
        addCardViewConstraint(cardView: cardView2)
        addImageViewConstraint(imageView: imageView1, contraintTo: cardView1)
        addImageViewConstraint(imageView: imageView2, contraintTo: cardView2)
        
        cardViewCenterPosition = cardView1.center
        
        // add UIPanGestureRecognizer to cardView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        cardView1.addGestureRecognizer(panGesture)
    }
    
    //MARK: - Share Action
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard let image = catDataManager.catImages.imageArray.first else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }
    
    //MARK: - Constraints Implementation
    
    // add constraints to cardView
    private func addCardViewConstraint(cardView: UIView) {
        let viewMargins = self.view.layoutMarginsGuide
        
        cardView.leadingAnchor.constraint(equalTo: viewMargins.leadingAnchor, constant: K.CardView.Constraint.leading).isActive = true
        cardView.trailingAnchor.constraint(equalTo: viewMargins.trailingAnchor, constant: K.CardView.Constraint.trailing).isActive = true
        cardView.centerYAnchor.constraint(equalTo: viewMargins.centerYAnchor).isActive = true
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
        
        // add style
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
    }
    
    //MARK: - Picture Fetching & Updating
    
    private func startFetchImage(initialRequest: Bool) {
        // first time loading image data
        if initialRequest {
            catDataManager.performRequest(imageDownloadNumber: K.Data.initialImageRequestNumber)
        } else {
            catDataManager.performRequest(imageDownloadNumber: K.Data.imageRequestNumber)
        }
    }

    // load first 2 images to the 2 cardViews
    internal func dataDidFetch() {
        let imageArray = catDataManager.catImages.imageArray
        // ensure there are more than 3 images ready to be viewed
        if imageArray.count >= 2 {
            DispatchQueue.main.async {
                self.imageView1.image = imageArray["Image1"]
                self.imageView2.image = imageArray["Image2"]
            }
            self.imageIndex += 2
        }
    }
    
    //MARK: - Card Animation & Rotation Section
    
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view else { return }
        let viewWidth = view.frame.width
        let cardDefaultPosition = CGPoint(x: self.view.center.x, y: self.view.center.y)
        let panGesture = sender
        
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
        
        /*
         The second card is visible when first card is dragged
         # if this method is not implemented,
            the user can see the removed card returns
            and inserts below the cardView
         */
        if sender.state == .began {
            if card == cardView1 {
                cardView2.isHidden = false
            } else {
                cardView1.isHidden = false
            }
        }
        
        // when user's finger left the screen
        if sender.state == .ended {
            // if card is moved to the left edge of the screen
            if card.center.x < viewWidth / 4 {
                UIView.animate(withDuration: 0.2) {
                    card.center = CGPoint(x: card.center.x - 800, y: card.center.y)
                }
                animateCard(card, panGesture: panGesture)
                
            }
            // if card is moved to the right edge of the screen
            else if card.center.x > viewWidth * 3/4 {
                UIView.animate(withDuration: 0.2) {
                    card.center = CGPoint(x: card.center.x + 800, y: card.center.y)
                    
                    // (TEST USE) update image
//                    self.updateCatImage()
                }
                animateCard(card, panGesture: panGesture)
                
            }
            else {
                // animate card back to origianl position, opacity and rotation state
                UIView.animate(withDuration: 0.2) {
                    card.center = cardDefaultPosition
                    card.alpha = 1.0
                    card.transform = CGAffineTransform.identity
                }
            }
            
            
        }
    }
    
    private func animateCard(_ card: UIView, panGesture: UIPanGestureRecognizer) {
        /*
         the card is hidden, remove attach to gesture recognizer
         has rotation back to original degree
         and removed from super view
         */
        card.isHidden = true
        card.removeGestureRecognizer(panGesture)
        card.transform = CGAffineTransform.identity
        card.removeFromSuperview()
        
        /*
         cardView at lower layer get gesture recognizer
         the removed cardView is inserted beneath it
         and has its position and contraint set
        */
        guard let cardDefaultCenter = cardViewCenterPosition else { return }
        
        if card == cardView1 {
            cardView2.addGestureRecognizer(panGesture)
            self.view.insertSubview(card, belowSubview: cardView2)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: cardView1)
            updateImageView(card)
        } else {
            cardView1.addGestureRecognizer(panGesture)
            self.view.insertSubview(card, belowSubview: cardView1)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: cardView2)
            updateImageView(card)
        }
        
    }
    
    private func updateImageView(_ cardView: UIView) {
        let imageArray = catDataManager.catImages.imageArray
        
//        if imageArray.count > 7 {
////            catDataManager.catImages.imageArray.removeFirst()
//        }
        imageIndex += 1
        
        switch cardView {
        case cardView1:
            if let nextImage = imageArray["Image\(imageIndex)"] {
                imageView1.image = nextImage
            } else {
                print("There is no new image for cardView1")
            }
            startFetchImage(initialRequest: false)
        case cardView2:
            if let nextImage = imageArray["Image\(imageIndex)"] {
                imageView2.image = nextImage
            } else {
                print("There is no new image for cardView2")
            }
            startFetchImage(initialRequest: false)
        default:
            return
        }
        
    }
    
    //MARK: - Error Handling Section
    
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

