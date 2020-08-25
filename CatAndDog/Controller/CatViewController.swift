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
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    
    var catDataManager = CatDataManager()
    let favDataManager = FavoriteDataManager()
    let cardView1 = UIView()
    let cardView2 = UIView()
    let imageView1 = UIImageView()
    let imageView2 = UIImageView()
    var cardViewDefaultPosition: CGPoint?
    var dataIndex: Int = 0
    var currentCardView: Int = 1
    var isInitialImageLoaded: Bool = false
    var isDataAvailable: Bool = true
    var cardView1Data: CatData?
    var cardView2Data: CatData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catDataManager.delegate = self
        
        // define toolBar's height
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true
        
        // download designated number of new images into imageArray
        fetchNewData(initialRequest: true)

        // create UIView, ImageView and constraints
        view.addSubview(cardView1)
        view.insertSubview(cardView2, belowSubview: cardView1)
        cardView1.addSubview(imageView1)
        cardView2.addSubview(imageView2)
        
        addCardViewConstraint(cardView: cardView1)
        addCardViewConstraint(cardView: cardView2)
        addImageViewConstraint(imageView: imageView1, contraintTo: cardView1)
        addImageViewConstraint(imageView: imageView2, contraintTo: cardView2)
        
        cardViewDefaultPosition = cardView1.center
        
        // Load up data saved in user's device
        favDataManager.loadImages()
        
        // TEST USE
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
    }
    
    //MARK: - Activity Indicator
    
    let indicator1 = UIActivityIndicatorView()
    let indicator2 = UIActivityIndicatorView()
    
    // indicator is placed right at the center of the cardView
    private func addIndicatorConstraint(indicator: UIActivityIndicatorView, constraintTo imageView: UIImageView) {
        let imageViewMargins = imageView.layoutMarginsGuide
        indicator.centerXAnchor.constraint(equalTo: imageViewMargins.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: imageViewMargins.centerYAnchor).isActive = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        // style
        indicator.style = .large
        indicator.hidesWhenStopped = true
    }
    
    private func addIndicator(to cardView: UIView) {
        switch cardView {
        case cardView1:
            imageView1.addSubview(indicator1)
            addIndicatorConstraint(indicator: indicator1, constraintTo: imageView1)
            indicator1.startAnimating()
        case cardView2:
            imageView2.addSubview(indicator2)
            addIndicatorConstraint(indicator: indicator2, constraintTo: imageView2)
            indicator2.startAnimating()
        default:
            return
        }
        
    }
    
    //MARK: - Favorite Action
    
    @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
        if currentCardView == 1 {
            favDataManager.saveData(cardView1Data!)
        } else {
            favDataManager.saveData(cardView2Data!)
        }
    }
    
    //MARK: - Share Action
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        var imageToShare = UIImage()
        switch currentCardView {
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
    
    //MARK: - Data Fetching & Updating
    
    private func fetchNewData(initialRequest: Bool) {
        // first time requesting image data
        if initialRequest {
            catDataManager.performRequest(imageDownloadNumber: K.Data.initialDataRequestNumber)
            addIndicator(to: cardView1)
        } else {
            catDataManager.performRequest(imageDownloadNumber: K.Data.dataRequestNumber)
        }
    }

    // Update UI using new data
    internal func dataDidFetch() {
        
        // TEST USE
        print("Data Array Count = \(catDataManager.dataIndex)")
        
        let dataSet = catDataManager.serializedData
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        
        if dataIndex == 0 {
            if let firstData = dataSet[self.dataIndex + 1] {
                
                cardView1Data = firstData
                
                DispatchQueue.main.async {
                    self.imageView1.image = firstData.image
                    self.dataIndex += 1
                    self.indicator1.stopAnimating()
                    self.favoriteBtn.isEnabled = true
                    
                    // add UIPanGestureRecognizer to cardView
                    self.cardView1.addGestureRecognizer(panGesture)
                }
            }
        } else if dataIndex == 1 {
            if let secondData = dataSet[self.dataIndex + 1] {
                
                cardView2Data = secondData
                
                DispatchQueue.main.async {
                    self.imageView2.image = secondData.image
                    self.dataIndex += 1
                    self.indicator2.stopAnimating()
                    self.favoriteBtn.isEnabled = true
                }
            }
        }
        
        // Update UI if new data was not available in the previous session
        if isDataAvailable == false {
            updateImageView()
        }
    }
    
    //MARK: - Card Animation & Rotation Section
    
    /// Handling the cardView's panning effect which is responded to user's input via finger dragging on the cardView itself.
    /// - Parameter sender: A concrete subclass of UIGestureRecognizer that looks for panning (dragging) gestures.
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let cardView = sender.view else { return }
        
        let viewWidth = view.frame.width
        let cardDefaultPosition = CGPoint(x: self.view.center.x, y: self.view.center.y)
        let panGesture = sender
        
        // point between the current pan and original location
        let fingerMovement = sender.translation(in: view)
        
        // amount of offset the card moved from its original position
        let xAxisPanOffset = cardView.center.x - cardDefaultPosition.x
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let cardRotationRadian = (rotationAtMax / 4) * (xAxisPanOffset / (viewWidth / 3))
        
        // determine the current displayed imageView
        var currentImageView = UIImageView()
        switch currentCardView {
        case 1:
            currentImageView = imageView1
        case 2:
            currentImageView = imageView2
        default:
            return
        }
        
        // card move to where the user's finger is
        cardView.center = CGPoint(x: cardDefaultPosition.x + fingerMovement.x, y: cardDefaultPosition.y + fingerMovement.y)
        
        // card's rotation increase when it approaches the side edge of the screen
        cardView.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
        
        /*
         The second card is visible when first card is dragged
         # if this method is not implemented,
            the user can see the removed card returns
            and inserts below the cardView
         */
        if sender.state == .began {
            if cardView == cardView1 {
                cardView2.isHidden = false
            } else {
                cardView1.isHidden = false
            }
        }
        
        // when user's finger left the screen
        if sender.state == .ended {
            /*
             Card can only be dismissed when it's dragged to the side of the screen
             and the current image view's image is not unavailable
             */
            if cardView.center.x < viewWidth / 4 && currentImageView.image != nil {
                UIView.animate(withDuration: 0.2) {
                    cardView.center = CGPoint(x: cardView.center.x - 400, y: cardView.center.y)
                }
                animateCard(cardView, panGesture: panGesture)
            }
            else if cardView.center.x > viewWidth * 3/4 && currentImageView.image != nil {
                UIView.animate(withDuration: 0.2) {
                    cardView.center = CGPoint(x: cardView.center.x + 400, y: cardView.center.y)
                }
                animateCard(cardView, panGesture: panGesture)
            }
            // animate card back to origianl position, opacity and rotation state
            else {
                UIView.animate(withDuration: 0.2) {
                    cardView.center = cardDefaultPosition
                    cardView.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    private func animateCard(_ card: UIView, panGesture: UIPanGestureRecognizer) {
        guard let cardDefaultCenter = cardViewDefaultPosition else { return }
        
        /*
         1. The dismissed card is hidden
         2. Remove attach to gesture recognizer
         3. Has rotation back to original degree
         4. Removed from super view
         */
        card.isHidden = true
        card.removeGestureRecognizer(panGesture)
        card.transform = CGAffineTransform.identity
        card.removeFromSuperview()
        
        /*
         1. CardView that was at the bottom has gesture recognizer attached
         2. The dismissed cardView is inserted beneath old cardView
         3. Set new cardView's position and contraint
         4. Update new card's imageView
         5. Download new image into image array
        */
        if card == cardView1 {
            currentCardView = 2
            cardView2.addGestureRecognizer(panGesture)
            self.view.insertSubview(card, belowSubview: cardView2)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: card)
            updateImageView()
            fetchNewData(initialRequest: false)
        } else if card == cardView2 {
            currentCardView = 1
            cardView1.addGestureRecognizer(panGesture)
            self.view.insertSubview(card, belowSubview: cardView1)
            card.center = cardDefaultCenter
            addCardViewConstraint(cardView: card)
            updateImageView()
            fetchNewData(initialRequest: false)
        } else {
            print("Error: The dismissed card is neither cardView1 nor cardView2")
        }
        
    }
    
    //MARK: - Update Image of imageView
    
    // Update cardView which was at the bottom if new data is availble
    private func updateImageView() {
        
        // TEST USE
        print("CardDataIndex = \(self.dataIndex)")
        
        let dataSet = catDataManager.serializedData
        if let newData = dataSet[dataIndex + 1] {
            isDataAvailable = true
            let newImage = newData.image
            
            // Check which cardView the data is to be allocated
            if (dataIndex + 1) % 2 == 1 {
                cardView1Data = newData
                DispatchQueue.main.async {
                    self.imageView1.image = newImage
                    self.indicator1.stopAnimating()
                    self.favoriteBtn.isEnabled = true
                }
                dataIndex += 1
            } else {
                cardView2Data = newData
                DispatchQueue.main.async {
                    self.imageView2.image = newImage
                    self.indicator2.stopAnimating()
                    self.favoriteBtn.isEnabled = true
                }
                dataIndex += 1
            }
        }
        // New data is not available
        else {
            isDataAvailable = false
            
            // Check which cardView's data is unavailable
            if (dataIndex + 1) % 2 == 1 {
                DispatchQueue.main.async {
                    self.imageView1.image = nil
                    self.addIndicator(to: self.cardView1)
                    self.favoriteBtn.isEnabled = false
                }
            } else {
                DispatchQueue.main.async {
                    self.imageView2.image = nil
                    self.addIndicator(to: self.cardView2)
                    self.favoriteBtn.isEnabled = false
                }
            }
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

