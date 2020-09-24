//
//  MainViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, NetworkManagerDelegate {
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    
    var networkManager = NetworkManager()
    let databaseManager = DatabaseManager()
    let cardView1 = UIView()
    let cardView2 = UIView()
    let imageView1 = UIImageView()
    let imageView2 = UIImageView()
    var cardViewAnchor = CGPoint()
    var dataIndex: Int = 0
    var currentCardView: Int = 1
    var isInitialImageLoaded: Bool = false
    var isNewDataAvailable: Bool = false
    var isCard1DataAvailable: Bool = false
    var isCard2DataAvailable: Bool = false
    var cardView1Data: CatData?
    var cardView2Data: CatData?
    var currentData: CatData? {
        if currentCardView == 1 {
            if let dataOne = cardView1Data {
                return dataOne
            }
        }
        else if currentCardView == 2 {
            if let dataTwo = cardView2Data {
                return dataTwo
            }
        } else {
            print("Invalid value of currentCardView")
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkManager.delegate = self
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true // define toolBar's height
        fetchNewData(initialRequest: true) // initiate data downloading

        // Add cardView, ImageView and implement neccesary contraints
        view.addSubview(cardView1)
        view.insertSubview(cardView2, belowSubview: cardView1)
        cardView1.addSubview(imageView1)
        cardView2.addSubview(imageView2)
        
        addCardViewConstraint(cardView: cardView1)
        addCardViewConstraint(cardView: cardView2)
        addImageViewConstraint(imageView: imageView1, contraintTo: cardView1)
        addImageViewConstraint(imageView: imageView2, contraintTo: cardView2)
        
        databaseManager.createDirectory() // Create folder for local image files store
        databaseManager.loadImages() // Load up data saved in user's device
        
        favoriteBtn.isEnabled = false // favorite button's default status
        
        // TEST AREA
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Refresh favorite button's image
        if let currentUsedData = currentData {
            let isDataSaved = databaseManager.isDataSaved(data: currentUsedData)
            DispatchQueue.main.async {
                self.favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Save the center position of the created card view
        cardViewAnchor = cardView1.center
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
        if let currentUsedData = currentData {
            let isDataSaved = databaseManager.isDataSaved(data: currentUsedData)
            
            // Save data if it's absent in database, otherwise delete data in database
            if isDataSaved == false {
                databaseManager.saveData(currentUsedData)
                DispatchQueue.main.async {
                    self.favoriteBtn.image = K.ButtonImage.filledHeart
                }
            } else if isDataSaved == true {
                // delete file in database
                databaseManager.deleteData(id: currentUsedData.id)
                
                DispatchQueue.main.async {
                    self.favoriteBtn.image = K.ButtonImage.heart
                }
            }
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
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewMargins = self.view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: viewMargins.leadingAnchor, constant: K.CardView.Constraint.leading),
            cardView.trailingAnchor.constraint(equalTo: viewMargins.trailingAnchor, constant: K.CardView.Constraint.trailing),
            cardView.centerYAnchor.constraint(equalTo: viewMargins.centerYAnchor, constant: K.CardView.Constraint.yAnchorOffset),
            cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: K.CardView.Constraint.heightToWidthRatio)
        ])
        
        // Style
        cardView.layer.cornerRadius = K.CardView.Style.cornerRadius
        cardView.layer.borderWidth = K.CardView.Style.borderWidth
        cardView.backgroundColor = K.CardView.Style.backgroundColor
    }
    
    // add constraints to imageView
    private func addImageViewConstraint(imageView: UIImageView, contraintTo cardView: UIView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: K.ImageView.Constraint.top),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: K.ImageView.Constraint.leading),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: K.ImageView.Constraint.trailing),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: K.ImageView.Constraint.bottom)
        ])
        
        // Style
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
    }
    
    //MARK: - Data Fetching & Updating
    
    private func fetchNewData(initialRequest: Bool) {
        // first time requesting image data
        if initialRequest {
            networkManager.performRequest(imageDownloadNumber: K.Data.initialDataRequestNumber)
            addIndicator(to: cardView1)
        } else {
            networkManager.performRequest(imageDownloadNumber: K.Data.dataRequestNumber)
        }
    }

    // Update UI using new data
    internal func dataDidFetch() {
        
        let dataSet = networkManager.serializedData
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        
        // update first cardView with first fetched data
        if dataIndex == 0 {
            if let firstData = dataSet[dataIndex + 1] {
                isNewDataAvailable = true
                
                cardView1Data = firstData
                isCard1DataAvailable = true
                let isDataSaved = databaseManager.isDataSaved(data: firstData) // determine whether data is available in database
                
                DispatchQueue.main.async {
                    self.imageView1.image = firstData.image
                    self.indicator1.stopAnimating()
                    
                    // set up favorite button status
                    self.favoriteBtn.isEnabled = true // enable favorite button
                    // set button's image as a filled-heart if data is already saved in database
                    if isDataSaved == true {
                        self.favoriteBtn.image = K.ButtonImage.filledHeart
                    }
                    
                    // add UIPanGestureRecognizer to cardView
                    self.cardView1.addGestureRecognizer(panGesture)
                }
                dataIndex += 1
            }
        } else if dataIndex == 1 {
            if let secondData = dataSet[dataIndex + 1] {
                
                isCard2DataAvailable = true
                cardView2Data = secondData
                
                DispatchQueue.main.async {
                    self.imageView2.image = secondData.image
                    self.indicator2.stopAnimating()
                }
                dataIndex += 1
            }
        }
        
        // Update UI if new data was not available in the previous UI updating session
        if isNewDataAvailable == false {
            updateCardView()
        }
    }
    
    //MARK: - Card Animation & Rotation Section
    
    /// Handling the cardView's panning effect which is responded to user's input via finger dragging on the cardView itself.
    /// - Parameter sender: A concrete subclass of UIGestureRecognizer that looks for panning (dragging) gestures.
    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        guard let cardView = sender.view else { return }
        
        let viewWidth = view.frame.width
        let panGesture = sender
        
        // Point of the finger in the view's coordinate system
        let fingerMovement = sender.translation(in: view)
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisPanOffset = cardView.center.x - cardViewAnchor.x
        
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
        cardView.center = CGPoint(x: cardViewAnchor.x + fingerMovement.x, y: cardViewAnchor.y + fingerMovement.y)
        
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
                    cardView.center = self.cardViewAnchor
                    cardView.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    private func animateCard(_ card: UIView, panGesture: UIPanGestureRecognizer) {
        
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
        if card == cardView1 { // dismissed cardView is cardView1
            currentCardView = 2
            cardView2.addGestureRecognizer(panGesture)
            
            // Favorite button is enabled if data is available
            favoriteBtn.isEnabled = isCard2DataAvailable ? true : false
            if let card2Data = cardView2Data {
                let isDataSaved = databaseManager.isDataSaved(data: card2Data) // determine whether data is already in database
                favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
            
            self.view.insertSubview(card, belowSubview: cardView2)
            card.center = cardViewAnchor
            addCardViewConstraint(cardView: card)
            
            updateCardView()
            fetchNewData(initialRequest: false)
        } else if card == cardView2 { // dismissed cardView is cardView2
            currentCardView = 1
            cardView1.addGestureRecognizer(panGesture)
            
            // Favorite button is enabled if data is available
            favoriteBtn.isEnabled = isCard1DataAvailable ? true : false
            if let card1Data = cardView1Data {
                let isDataSaved = databaseManager.isDataSaved(data: card1Data) // determine whether data is already in database
                favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
            
            self.view.insertSubview(card, belowSubview: cardView1)
            card.center = cardViewAnchor
            addCardViewConstraint(cardView: card)
            
            updateCardView()
            fetchNewData(initialRequest: false)
        } else {
            print("Error: The dismissed card is neither cardView1 nor cardView2")
        }
    }
    
    //MARK: - Update Image of imageView
    
    // Prepare the next cardView to be shown
    private func updateCardView() {
        
        let dataSet = networkManager.serializedData
        if let newData = dataSet[dataIndex + 1] { // determine whether new data is available
            
            let newImage = newData.image
            
            // Check to which cardView the data is to be allocated
            if (dataIndex + 1) % 2 == 1 { // new data is for cardView 1
                DispatchQueue.main.async {
                    self.imageView1.image = newImage
                    self.indicator1.stopAnimating()
                }
                dataIndex += 1
                cardView1Data = newData
                isCard1DataAvailable = true
            } else { // new data is for cardView 2
                DispatchQueue.main.async {
                    self.imageView2.image = newImage
                    self.indicator2.stopAnimating()
                }
                dataIndex += 1
                isCard2DataAvailable = true
                cardView2Data = newData
            }
            
            // set isNewDataAvailable true if next cardView's data is available, vice versa
            if currentCardView == 1 {
                if cardView2Data != nil {
                    isNewDataAvailable = true
                }
            } else if currentCardView == 2 {
                if cardView1Data != nil {
                    isNewDataAvailable = true
                }
            }
        }
        // New data is not available
        else {
            // set both cardViews' UI to loading status if no data is available for both cardViews
            if isNewDataAvailable == false {
                if currentCardView == 1 {
                    DispatchQueue.main.async {
                        self.imageView2.image = nil
                        self.addIndicator(to: self.cardView2)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.imageView1.image = nil
                        self.addIndicator(to: self.cardView1)
                    }
                }
                cardView1Data = nil
                cardView2Data = nil
            }
            
            isNewDataAvailable = false // trigger method updateCardView to be executed when new data is fetched successfully
            
            // new data for cardView 1 is not available
            if (dataIndex + 1) % 2 == 1 {
                DispatchQueue.main.async {
                    self.imageView1.image = nil
                    self.addIndicator(to: self.cardView1)
                }
                isCard1DataAvailable = false
                cardView1Data = nil
            }
            // new data for cardView 2 is not available
            else {
                DispatchQueue.main.async {
                    self.imageView2.image = nil
                    self.addIndicator(to: self.cardView2)
                }
                isCard2DataAvailable = false
                cardView2Data = nil
            }
        }
    }
    
    //MARK: - Error Handling Section
    
    // error occured in the data fetching process
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

