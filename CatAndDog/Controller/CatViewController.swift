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
    var currentDisplayCardViewIndex: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // define toolBar's height
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true
        
        // download designated number of new images into imageArray
        fetchNewImage(initialRequest: true, for: cardView1)

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
        
    }
    
    //MARK: - Activity Indicator
    
    let indicator = UIActivityIndicatorView()
    // indicator is placed right at the center of the cardView
    private func addIndicatorConstraint(indicator: UIActivityIndicatorView, constraintTo cardView: UIView) {
        let cardViewMargins = cardView.layoutMarginsGuide
        indicator.centerXAnchor.constraint(equalTo: cardViewMargins.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: cardViewMargins.centerYAnchor).isActive = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        // style
        indicator.style = .large
        indicator.hidesWhenStopped = true
    }
    
    //MARK: - Share Action
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        var imageToShare = UIImage()
        switch currentDisplayCardViewIndex {
        case 1:
            guard let image1 = imageView1.image else { return }
            imageToShare = image1
        case 2:
        guard let image2 = imageView2.image else { return }
            imageToShare = image2
        default:
            print("No Image available to share")
            return
        }
        // present activity controller
        let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
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
    
    private func fetchNewImage(initialRequest: Bool, for cardView: UIView) {
        // first time requesting image data
        if initialRequest {
            catDataManager.performRequest(imageDownloadNumber: K.Data.initialImageRequestNumber)
        } else {
            catDataManager.performRequest(imageDownloadNumber: K.Data.imageRequestNumber)
        }
    }

    // initial 2 images have been downloaded
    internal func dataDidFetch() {
        let imageArray = catDataManager.catImages.imageArray
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        // ensure there are more than 3 images ready to be viewed
        if imageArray.count >= 2 {
            DispatchQueue.main.async {
                self.imageView1.image = imageArray["Image1"]
                self.imageView2.image = imageArray["Image2"]
                self.indicator.stopAnimating()

                // add UIPanGestureRecognizer to cardView
                self.cardView1.addGestureRecognizer(panGesture)
                print("test")
            }
            self.imageIndex += 2

        }
    }
    
    //MARK: - Card Animation & Rotation Section
    
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let pannedCard = sender.view else { return }
        let viewWidth = view.frame.width
        let cardDefaultPosition = CGPoint(x: self.view.center.x, y: self.view.center.y)
        let panGesture = sender
        
        // point between the current pan and original location
        let fingerMovement = sender.translation(in: view)
        
        // amount of offset the card moved from its original position
        let xAxisPanOffset = pannedCard.center.x - cardDefaultPosition.x
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let cardRotationRadian = (rotationAtMax / 4) * (xAxisPanOffset / (viewWidth / 3))
        
        // card move to where the user's finger is
        pannedCard.center = CGPoint(x: cardDefaultPosition.x + fingerMovement.x, y: cardDefaultPosition.y + fingerMovement.y)
        
        // card's rotation increase when it approaches the side edge of the screen
        pannedCard.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
        
        /*
         The second card is visible when first card is dragged
         # if this method is not implemented,
            the user can see the removed card returns
            and inserts below the cardView
         */
        if sender.state == .began {
            if pannedCard == cardView1 {
                cardView2.isHidden = false
            } else {
                cardView1.isHidden = false
            }
        }
        
        // when user's finger left the screen
        if sender.state == .ended {
            // if card is moved to the left edge of the screen
            if pannedCard.center.x < viewWidth / 4 && catDataManager.numberOfNewImages > 0 {
                UIView.animate(withDuration: 0.2) {
                    pannedCard.center = CGPoint(x: pannedCard.center.x - 800, y: pannedCard.center.y)
                }
                animateCard(pannedCard, panGesture: panGesture)
            }
            // if card is moved to the right edge of the screen
            else if pannedCard.center.x > viewWidth * 3/4 && catDataManager.numberOfNewImages > 0 {
                UIView.animate(withDuration: 0.2) {
                    pannedCard.center = CGPoint(x: pannedCard.center.x + 800, y: pannedCard.center.y)
                }
                animateCard(pannedCard, panGesture: panGesture)
            }
            else {
                // animate card back to origianl position, opacity and rotation state
                UIView.animate(withDuration: 0.2) {
                    pannedCard.center = cardDefaultPosition
                    pannedCard.alpha = 1.0
                    pannedCard.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    private func animateCard(_ card: UIView, panGesture: UIPanGestureRecognizer) {
        guard let cardDefaultCenter = cardViewCenterPosition else { return }
        
        /*
         1. the card is hidden
         2. remove attach to gesture recognizer
         3. has rotation back to original degree
         4. and removed from super view
         */
        card.isHidden = true
        card.removeGestureRecognizer(panGesture)
        card.transform = CGAffineTransform.identity
        card.removeFromSuperview()
        catDataManager.numberOfNewImages -= 1
        
        /*
         1. cardView at lower layer has gesture recognizer attached
         2. the removed cardView is inserted beneath it
         3. and has its position and contraint set
        */
        if card == cardView1 {
            cardView2.addGestureRecognizer(panGesture)
            
            currentDisplayCardViewIndex = 2
            self.view.insertSubview(card, belowSubview: cardView2)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: cardView1)
            updateImageView(card)
        } else if card == cardView2 {
            cardView1.addGestureRecognizer(panGesture)
            
            currentDisplayCardViewIndex = 1
            self.view.insertSubview(card, belowSubview: cardView1)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: cardView2)
            updateImageView(card)
        } else {
            print("The dragged away card is neither cardView1 or cardView2")
        }
        
    }
    
    //MARK: - Update Image of imageView
    
    // image will be updated after cardView is dismissed
    private func updateImageView(_ cardView: UIView) {
        let imageArray = catDataManager.catImages.imageArray
        
        fetchNewImage(initialRequest: false, for: cardView)
        imageIndex += 1
        
        switch cardView {
        case cardView1:
            if let nextImage = imageArray["Image\(imageIndex)"] {
                imageView1.image = nextImage
            } else {
                imageView1.image = nil
                print("There is no new image for cardView1")
            }
        case cardView2:
            if let nextImage = imageArray["Image\(imageIndex)"] {
                imageView2.image = nextImage
            } else {
                imageView2.image = nil
                print("There is no new image for cardView2")
            }
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

