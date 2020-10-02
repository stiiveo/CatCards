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
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    
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
        
        // Disable toolbar buttons until first image is loaded
        favoriteBtn.isEnabled = false
        shareBtn.isEnabled = false
        
        // TEST AREA
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh favorite button's image
        if let currentUsedData = currentData {
            let isDataSaved = databaseManager.isDataSaved(data: currentUsedData)
            DispatchQueue.main.async {
                self.favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    // Add constraints to cardView
    private func addCardViewConstraint(cardView: UIView) {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        let viewMargins = self.view.layoutMarginsGuide
        let toolbarMargins = self.toolBar.layoutMarginsGuide
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: viewMargins.leadingAnchor, constant: K.CardView.Constraint.leading),
            cardView.trailingAnchor.constraint(equalTo: viewMargins.trailingAnchor, constant: K.CardView.Constraint.trailing),
            cardView.topAnchor.constraint(equalTo: viewMargins.topAnchor, constant: K.CardView.Constraint.top),
            cardView.bottomAnchor.constraint(equalTo: toolbarMargins.topAnchor, constant: K.CardView.Constraint.bottom)
        ])
        
        // Style
        cardView.backgroundColor = K.CardView.Style.backgroundColor
        cardView.layer.cornerRadius = K.CardView.Style.cornerRadius
        
        // Shadow
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = .zero
        cardView.layer.shadowRadius = 5
        cardView.layer.shouldRasterize = true
        cardView.layer.rasterizationScale = UIScreen.main.scale
    }
    
    // Add constraints to imageView
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
                
                // Determine if downloaded data already exist in database
                let isDataSaved = databaseManager.isDataSaved(data: firstData)
                
                DispatchQueue.main.async {
                    self.imageView1.image = firstData.image
                    self.indicator1.stopAnimating()
                    
                    // Enable toolbar buttons
                    self.favoriteBtn.isEnabled = true // enable favorite button
                    self.shareBtn.isEnabled = true
                    
                    // Set button's image as a filled heart indicating data is already in database
                    if isDataSaved == true {
                        self.favoriteBtn.image = K.ButtonImage.filledHeart
                    }
                    // Add UIPanGestureRecognizer to cardView1
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
                    
                    // Add pan gesture recognizer to cardView2 and disable it
                    self.cardView2.addGestureRecognizer(panGesture)
                    if let cardView2GR = self.cardView2.gestureRecognizers?.first {
                        cardView2GR.isEnabled = false
                    }
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
        
        // when user's finger left the screen
        if sender.state == .ended {
            /*
             Card can only be dismissed when it's dragged to the side of the screen
             and the current image view's image is available
             */
            let releasePoint = CGPoint(x: cardView.frame.midX, y: cardView.frame.midY)
            
            if cardView.center.x < viewWidth / 4 && currentImageView.image != nil { // card was at the left side of the screen
                animateCard(cardView, releasedPoint: releasePoint)
            }
            else if cardView.center.x > viewWidth * 3/4 && currentImageView.image != nil { // card was at the right side of the screen
                animateCard(cardView, releasedPoint: releasePoint)
            }
            // Reset card's position and rotation state
            else {
                UIView.animate(withDuration: 0.2) {
                    cardView.center = self.cardViewAnchor
                    cardView.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    private func animateCard(_ card: UIView, releasedPoint: CGPoint) {
        // Determine the quarant of the release point
        var quadrant: Int?
        let releasePointX = releasedPoint.x
        let releasePointY = releasedPoint.y
        let anchorX = cardViewAnchor.x
        let anchorY = cardViewAnchor.y
        
        if releasePointX > anchorX && releasePointY <= anchorY {
            quadrant = 1
        } else if releasePointX < anchorX && releasePointY <= anchorY {
            quadrant = 2
        } else if releasePointX < anchorX && releasePointY > anchorY {
            quadrant = 3
        } else if releasePointX > anchorX && releasePointY > anchorY {
            quadrant = 4
        }
        
        // Move the card to the edge of either side of the screen depending on where the card was released at
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            guard quadrant != nil else { return }
            let offsetAmount = UIScreen.main.bounds.width
            switch quadrant! {
            case 1:
                card.center = CGPoint(x: card.center.x + offsetAmount, y: card.center.y - offsetAmount)
            case 2:
                card.center = CGPoint(x: card.center.x - offsetAmount, y: card.center.y - offsetAmount)
            case 3:
                card.center = CGPoint(x: card.center.x - offsetAmount, y: card.center.y + offsetAmount)
            case 4:
                card.center = CGPoint(x: card.center.x + offsetAmount, y: card.center.y + offsetAmount)
            default:
                print("Quadrant of the finger release point is invalid.")
            }
            
        } completion: { (true) in
            if true {
                if let cardGR = card.gestureRecognizers?.first {
                    cardGR.isEnabled = false
                }
                card.removeFromSuperview()
                card.transform = CGAffineTransform.identity
                self.rotateCard(dismissedView: card)
            }
        }
    }
        
    func rotateCard(dismissedView: UIView) {
        /*
         1. Update favorite button's status
         2. Place the dismissed card beneath the current cardView
         3. Set up dismissed card's position and contraint
         4. Update imageView's image
         5. Fetch new data
         6. Enable gesture recognizer
        */
        if dismissedView == cardView1 { // dismissed cardView is cardView1
            currentCardView = 2
            if let cardGR = cardView2.gestureRecognizers?.first {
                cardGR.isEnabled = true
            }
            
            // Favorite button is enabled if data is available
            favoriteBtn.isEnabled = isCard2DataAvailable ? true : false
            if let card2Data = cardView2Data {
                let isDataSaved = databaseManager.isDataSaved(data: card2Data) // determine whether data is already in database
                favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
            
            // Put the dismissed card behind the current card
            self.view.insertSubview(dismissedView, belowSubview: cardView2)
            dismissedView.center = cardViewAnchor
            addCardViewConstraint(cardView: dismissedView)
            
            updateCardView()
            fetchNewData(initialRequest: false)
        } else if dismissedView == cardView2 { // dismissed cardView is cardView2
            currentCardView = 1
            if let cardGR = cardView1.gestureRecognizers?.first {
                cardGR.isEnabled = true
            }
            
            // Favorite button is enabled if data is available
            favoriteBtn.isEnabled = isCard1DataAvailable ? true : false
            if let card1Data = cardView1Data {
                let isDataSaved = databaseManager.isDataSaved(data: card1Data) // determine whether data is already in database
                favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
            
            // Put the dismissed card behind the current card
            self.view.insertSubview(dismissedView, belowSubview: cardView1)
            dismissedView.center = cardViewAnchor
            addCardViewConstraint(cardView: dismissedView)
            
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
                cardView2Data = newData
                isCard2DataAvailable = true
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
    
    // Present error message to the user if any error occurs in the data fetching process
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

