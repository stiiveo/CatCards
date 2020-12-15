//
//  MainViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import GoogleMobileAds
import UserNotifications

private enum Card {
    case firstCard, secondCard
}

private enum CurrentView {
    case first, second, undo
}

class MainViewController: UIViewController, NetworkManagerDelegate {
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    @IBOutlet weak var undoBtn: UIBarButtonItem!
    @IBOutlet weak var adFixedSpace: UIView!
    @IBOutlet weak var adFixedSpaceHeight: NSLayoutConstraint!
    @IBOutlet weak var goToCollectionViewBtn: UIBarButtonItem!
    
    private var networkManager = NetworkManager()
    private let databaseManager = DatabaseManager()
    private let defaults = UserDefaults.standard
    private let firstCard = CardView()
    private let secondCard = CardView()
    private let undoCard = CardView()
    private var cardViewAnchor = CGPoint()
    private var imageViewAnchor = CGPoint()
    private var cardsAreCreated = false
    private var dataIndex: Int = 0
    private var currentCard: CurrentView = .first
    private var nextCard: Card = .secondCard
    private var cardHintDisplayed = false
    private var toolbarHintDisplayed = false
    
    private var viewCount: Int! {
        didSet {
            //..
        }
    } // Number of cards with cat images the user has seen
    
    private var currentData: CatData? {
        switch currentCard {
        case .first:
            return firstCard.data
        case .second:
            return secondCard.data
        case .undo:
            return undoCard.data
        }
    }
    
    private lazy var panCard: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan))
        pan.delegate = self
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        return pan
    }()
    
    private lazy var zoomImage: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleImageZoom))
        pinch.delegate = self
        return pinch
    }()
    
    private lazy var panImage: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleImagePan))
        pan.delegate = self
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        return pan
    }()
    
    private lazy var adBannerView: GADBannerView = {
        // Initialize ad banner
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait) // Define ad banner's size
        adBannerView.adUnitID = K.Banner.unitID
        adBannerView.rootViewController = self
        adBannerView.delegate = self
        
        return adBannerView
    }()
    
    //MARK: - View Overriding Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkManager.delegate = self
        fetchNewData(initialRequest: true) // initiate data downloading
        
        // Create local image folder in file system or load data from it if it already exists
        databaseManager.createDirectory()
        databaseManager.getImageFileURLs()
        
        // Configure default status of toolbar's item buttons
        favoriteBtn.isEnabled = false
        shareBtn.isEnabled = false
        undoBtn.isEnabled = false
        
        setDownsampleSize() // Prepare ImageProcess's operation parameter
        
        // Load value from defaults if there's any
        let savedViewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        self.viewCount = (savedViewCount != 0) ? savedViewCount : 0
        
        // Notify this VC that when the app entered the background, execute selected method.
        NotificationCenter.default.addObserver(self, selector: #selector(saveViewCount), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh favorite button's image
        refreshButtonState()
        
        // Hide navigation bar's border line
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = K.Color.backgroundColor
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // Hide toolbar's hairline
        self.toolBar.clipsToBounds = true
        self.toolBar.barTintColor = K.Color.backgroundColor
        self.toolBar.isTranslucent = false
        
        addBannerToView(adBannerView)
        
        // * CardView can only be added to the view after the height of the ad banner is known.
        addCardViews()
        
        // Hide the toolbar and nav-bar item to prepare for new user onboarding tutorial
        if isOldUser() {
            disableAllButtons()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get the default position of cardView and cardView's imageView
        cardViewAnchor = (cardViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? firstCard.center : cardViewAnchor
        imageViewAnchor = (imageViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? firstCard.imageView.center : imageViewAnchor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Un-hidden nav bar's hairline
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Reload the banner's ad if the orientation of the screen is about to change
        coordinator.animate { _ in
            self.loadBannerAd()
        }
    }
    
    //MARK: - Onboarding Methods
    
    private var hintView: UIView!
    private var hintLabel: UILabel!
    private var topConstraint1: NSLayoutConstraint!
    private var topConstraint2: NSLayoutConstraint!
    
    /// Teach the user how each button of toolbar works
    private func displayToolbarTutorial() {
        guard !toolbarHintDisplayed else { return } // Make sure the tutorial was not displayed before.
        
        // Move the hintView to overlay at the bottom of the cardView
        topConstraint2 = hintView.topAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)
        
        // Hide the hintView with the first tutorial message
        UIView.animate(withDuration: 0.5) {
            self.hintView.alpha = 0
        } completion: { _ in
            // Set hintView's new top anchor constraint
            self.topConstraint1.isActive = false
            self.topConstraint2.isActive = true
            
            // Set second hintView's tutorial message
            self.hintLabel.text = "Share current image."
            self.hintLabel.textAlignment = .center
            
            // Enable share button
            self.shareBtn.isEnabled = true
            
            // Show the second hint view
            UIView.animate(withDuration: 0.8, delay: 0.2) {
                self.toolBar.alpha = 1
                self.hintView.alpha = 1
            } completion: { _ in
                // Hide hintView
                UIView.animate(withDuration: 0.8, delay: 1.5) {
                    self.hintLabel.alpha = 0
                } completion: { _ in
                    // Enable the undo button only and update the hintLabel
                    self.shareBtn.isEnabled = false
                    self.undoBtn.isEnabled = true
                    self.hintLabel.text = "Undo the last swiped card."
                    UIView.animate(withDuration: 0.5) {
                        self.hintLabel.alpha = 1
                    } completion: { _ in
                        // Hide the hintView
                        UIView.animate(withDuration: 0.8, delay: 1.5) {
                            self.hintLabel.alpha = 0
                        } completion: { _ in
                            self.undoBtn.isEnabled = false
                            self.favoriteBtn.isEnabled = true
                            self.hintLabel.text = "Save the current image."
                            UIView.animate(withDuration: 0.5) {
                                self.hintLabel.alpha = 1
                            } completion: { _ in
                                // Hide the hintView
                                UIView.animate(withDuration: 0.8, delay: 1.5) {
                                    self.hintView.alpha = 0
                                } completion: { _ in
                                    // Enable all toolbar buttons
                                    self.shareBtn.isEnabled = true
                                    self.undoBtn.isEnabled = true
                                    self.toolbarHintDisplayed = true
                                }

                            }

                        }

                    }

                }
            }
        }

    }
    
    /// Teach the user how the swiping gesture works
    private func displayCardTutorial() {
        guard !cardHintDisplayed else { return } // Make sure the tutorial was not displayed before.
        
        self.hintView = UIView()
        self.hintLabel = UILabel()
        let anchorPoint = self.cardViewAnchor
        
        // Add message block to view
        view.insertSubview(hintView, belowSubview: firstCard)
        hintView.translatesAutoresizingMaskIntoConstraints = false
        
        topConstraint1 = hintView.topAnchor.constraint(equalTo: toolBar.topAnchor, constant: 10)
        NSLayoutConstraint.activate([
            topConstraint1,
            hintView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            hintView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
        
        // Message block style
        hintView.backgroundColor = K.Color.hintViewBackground
        hintView.layer.cornerRadius = 10
        
        // Add text label to message block
        hintView.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: hintView.topAnchor, constant: 15),
            hintLabel.leadingAnchor.constraint(equalTo: hintView.leadingAnchor, constant: 15),
            hintLabel.trailingAnchor.constraint(equalTo: hintView.trailingAnchor, constant: -15),
            hintLabel.bottomAnchor.constraint(equalTo: hintView.bottomAnchor, constant: -15)
        ])
        
        // Text label style
        hintLabel.text = "Swipe the card to reveal the next cat image."
        hintLabel.textColor = K.Color.backgroundColor
        hintLabel.font = .systemFont(ofSize: 20, weight: .medium)
        hintLabel.adjustsFontSizeToFitWidth = true
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .natural
        
        // Animate the appearence of the message block
        hintView.alpha = 0
        UIView.animate(withDuration: 0.8, delay: 0.2) {
            self.hintView.alpha = 1

        } completion: { _ in
            // Rotate the first card to hint the user how swiping gesture works
            // Rotate the first card to right
            UIView.animate(withDuration: 0.4, delay: 0.5) {
                self.firstCard.transform = CGAffineTransform(rotationAngle: 0.1)
                self.firstCard.center = CGPoint(x: anchorPoint.x + 20, y: anchorPoint.y)
            } completion: { _ in
                // Rotate the first card to left
                UIView.animate(withDuration: 0.4, delay: 0.0) {
                    self.firstCard.transform = CGAffineTransform(rotationAngle: -0.1)
                    self.firstCard.center = CGPoint(x: anchorPoint.x - 20, y: anchorPoint.y)
                } completion: { _ in
                    // Rotate the first card back to original position
                    UIView.animate(withDuration: 0.4) {
                        self.firstCard.transform = .identity
                        self.firstCard.center = anchorPoint
                    } completion: { _ in
                        self.cardHintDisplayed = true
                    }

                }
            }
        }
        
    }
    
    /// Disable and hide button items in nav-bar and toolbar
    private func disableAllButtons() {
        navigationController?.navigationBar.tintColor = K.Color.backgroundColor
        goToCollectionViewBtn.isEnabled = false
        
        toolBar.alpha = 0
        shareBtn.isEnabled = false
        undoBtn.isEnabled = false
        favoriteBtn.isEnabled = false
    }
    
    //MARK: - Ad Banner Methods
    
    private func loadBannerAd() {
        // Create an ad request and load the adaptive banner ad.
        adBannerView.load(GADRequest())
    }
    
    /// Place the banner at the center of the reserved ad space
    private func addBannerToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        adFixedSpace.addSubview(bannerView)
        
        // Note that the size of the adaptive ad banner is returned by Google,
        // therefore defining height or width here is not necessary.
        NSLayoutConstraint.activate([
            bannerView.centerYAnchor.constraint(equalTo: adFixedSpace.centerYAnchor),
            bannerView.centerXAnchor.constraint(equalTo: adFixedSpace.centerXAnchor)
        ])
        
        // Determine the view width to use for the ad width.
        let frame = { () -> CGRect in
            // Here safe area is taken into account, hence the view frame is used
            // after the view has been laid out.
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        let viewWidth = frame.size.width
        
        // Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        
        // Set the height of the reserved ad space the same as the adaptive banner's height
        adFixedSpaceHeight.constant = bannerView.frame.height
        adFixedSpace.layoutIfNeeded()
    }
    
    //MARK: - Support Methods
    
    /// Save the value of card view count to user defaults
    @objc func saveViewCount() {
        guard viewCount != nil else { return }
        defaults.setValue(viewCount, forKey: K.UserDefaultsKeys.viewCount)
    }
    
    /// Determine if the user is the new user
    private func isOldUser() -> Bool {
        // Make sure the bool value exists
        if defaults.bool(forKey: K.UserDefaultsKeys.isOldUser) {
            return true
        } else {
            // Set the value to true
            defaults.setValue(true, forKey: K.UserDefaultsKeys.isOldUser)
            return false
        }
    }
    
    /// Determine the downsample size of image by calculating the thumbnail's width footprint on the user's device
    private func setDownsampleSize() {
        // Device with wider screen (iPhone Plus and Max series) has one more cell per row than other devices
        let screenWidth = UIScreen.main.bounds.width
        let wideScreenWidth: CGFloat = 414 // Point width of iPhone Plus or Max series
        let cellsPerRow: CGFloat = (screenWidth >= wideScreenWidth) ? 4.0 : 3.0
        let cellSpacing: CGFloat = 1.5 // Space between each cell
        
        // Floor the calculated width to remove any decimal number
        let cellWidth = floor((screenWidth - (cellSpacing * (cellsPerRow - 1))) / cellsPerRow)
        
        let cellSize = CGSize(width: cellWidth, height: cellWidth)
        databaseManager.imageProcess.cellSize = cellSize
    }
    
    //MARK: - Toolbar Button Method and State Control
    
    private func refreshButtonState() {
        guard toolbarHintDisplayed else { return }
        
        let dataIsLoaded = currentData != nil
        
        // Toggle the availability of toolbar buttons
        favoriteBtn.isEnabled = dataIsLoaded ? true : false
        shareBtn.isEnabled = dataIsLoaded ? true : false
        undoBtn.isEnabled = true
        
        // Toggle the status of favorite button
        if let data = currentData {
            let isDataSaved = databaseManager.isDataSaved(data: data)
            favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    // Undo Action
    
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        undoBtn.isEnabled = false
        
        // Remove current card's gesture recognizer and save its reference
        switch currentCard {
        case .first:
            removeGestureRecognizers(from: firstCard)
            nextCard = .firstCard
        case .second:
            self.removeGestureRecognizers(from: secondCard)
            nextCard = .secondCard
        case .undo:
            debugPrint("Error: Undo button should have not been enabled")
        }
        
        // Place undo card in front of the current card
        view.addSubview(undoCard)
        addCardViewConstraint(card: undoCard)
        
        UIView.animate(withDuration: 0.5) { // Introduction of undo card
            self.undoCard.center = self.cardViewAnchor
            self.undoCard.transform = .identity
            self.firstCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.secondCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { (true) in
            if true {
                self.attachGestureRecognizers(to: self.undoCard)
                self.currentCard = .undo
                self.refreshButtonState()
            }
        }
    }
    
    // Data Saving Method
    
    @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
        if let data = currentData {
            // Save data if it's absent in database, otherwise delete it in database
            let isDataSaved = databaseManager.isDataSaved(data: data)
            switch isDataSaved {
            case false:
                databaseManager.saveData(data)
                self.favoriteBtn.image = K.ButtonImage.filledHeart
            case true:
                databaseManager.deleteData(id: data.id, atIndex: 0)
                self.favoriteBtn.image = K.ButtonImage.heart
            }
        }
    }
    
    // Image Sharing Method
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        if let imageToShare = currentData?.image {
            let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
            present(activityController, animated: true)
        }
    }
    
    //MARK: - Constraints and Style Method
    
    /// Add two cardViews to the view and shrink the second card's size.
    private func addCardViews() {
        if cardsAreCreated {
            return
        } else {
            view.addSubview(firstCard)
            view.insertSubview(secondCard, belowSubview: firstCard)
            
            addCardViewConstraint(card: firstCard)
            addCardViewConstraint(card: secondCard)
            secondCard.transform = CGAffineTransform(scaleX: K.CardView.Size.transform, y: K.CardView.Size.transform)
            
            cardsAreCreated = true
        }
    }
    
    /// Add constraints to cardView
    private func addCardViewConstraint(card: CardView) {
        // Constraint
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: K.CardView.Constraint.leading
            ),
            card.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: K.CardView.Constraint.trailing
            ),
            card.topAnchor.constraint(
                equalTo: self.view.topAnchor,
                constant: K.CardView.Constraint.top
            ),
            card.bottomAnchor.constraint(
                equalTo: self.toolBar.topAnchor,
                constant: K.CardView.Constraint.bottom)
        ])
        
        // Style
        card.backgroundColor = K.CardView.Style.backgroundColor
        card.layer.cornerRadius = K.CardView.Style.cornerRadius
        
        // Shadow
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.2
        card.layer.shadowOffset = .zero
        card.layer.shadowRadius = 5
        card.layer.shouldRasterize = true
        card.layer.rasterizationScale = UIScreen.main.scale
    }
    
    //MARK: - Data Fetching & Updating
    
    private func fetchNewData(initialRequest: Bool) {
        switch initialRequest {
        case true:
            networkManager.performRequest(numberOfRequests: K.Data.maxOfCachedData)
        case false:
            networkManager.performRequest(numberOfRequests: 1)
        }
    }
    
    // Update UI when new data is downloaded succesfully
    internal func dataDidFetch() {
        let dataSet = networkManager.serializedData
        
        // Update image, buttons and attach gesture recognizers
        switch dataIndex {
        case 0:
            if let firstData = dataSet[dataIndex + 1] {
                dataIndex += 1
                firstCard.data = firstData
                viewCount += 1 // Increment the number of cat the user has seen
                
                DispatchQueue.main.async {
                    // Refresh toolbar buttons' state
                    self.refreshButtonState()
                    
                    // Add gesture recognizer to first card
                    self.attachGestureRecognizers(to: self.firstCard)
                    
                    // ! TEST PARAMETER, CHANGE AFTER TESTING !
                    if self.isOldUser() {
                        self.displayCardTutorial()
                    }
                    
//                    // Load banner ad after first card is loaded
//                    self.loadBannerAd()
                }
            }
        case 1:
            if let secondData = dataSet[dataIndex + 1] {
                secondCard.data = secondData
                dataIndex += 1
            }
        default:
            if firstCard.data == nil || secondCard.data == nil {
                updateCardView()
            }
        }
    }
    
    //MARK: - Cards Rotation Section
    
    private func rotateCard(_ card: CardView) {
        nextCard = (card == firstCard) ? .firstCard : .secondCard
        self.currentCard = (nextCard == .firstCard) ? .second : .first
        
        card.data = nil
        let currentCard = (self.currentCard == .first) ? firstCard : secondCard
        attachGestureRecognizers(to: currentCard)
        
        // Update the count of view the user has seen if the current card's data is valid
        if currentData != nil {
            viewCount += 1
        }
        
        // Put the dismissed card behind the current card
        self.view.insertSubview(card, belowSubview: currentCard)
        card.center = cardViewAnchor
        addCardViewConstraint(card: card)
        
        // Shrink the size of the newly added card view
        card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        updateCardView()
        fetchNewData(initialRequest: false)
    }
    
    //MARK: - Update Image of imageView
    
    /// Update card's content if new data is available.
    private func updateCardView() {
        let dataSet = networkManager.serializedData
        let dataAllocation: Card = ((self.dataIndex + 1) % 2 == 1) ? .firstCard : .secondCard
        
        // Increment the view count if card's data is invalid and about to be updated
        if currentData == nil {
            self.viewCount += 1
        }
        
        if let newData = dataSet[dataIndex + 1] { // Make sure new data is available
            switch dataAllocation { // Decide which card the data is to be allocated
            case .firstCard:
                firstCard.data = newData
                dataIndex += 1
            case .secondCard:
                secondCard.data = newData
                dataIndex += 1
            }
        }
        
        DispatchQueue.main.async {
            self.refreshButtonState()
        }
    }
    
    //MARK: - Card Panning Methods
    
    private enum Side {
        case upper, lower
    }
    
    private var firstFingerLocation: Side?
    
    /// Handling the cardView's panning effect which is responded to user's input via finger dragging on the cardView itself.
    /// - Parameter sender: A concrete subclass of UIGestureRecognizer that looks for panning (dragging) gestures.
    @objc private func handleCardPan(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? CardView else { return }
        
        let halfViewWidth = view.frame.width / 2
        
        // Point of the finger in the view's coordinate system
        let fingerPosition = sender.location(in: sender.view)
        let side: Side = fingerPosition.y < card.frame.midY ? .upper : .lower
        firstFingerLocation = (firstFingerLocation == nil) ? side : firstFingerLocation // variable can only be set once
        
        let fingerMovement = sender.translation(in: view)
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisOffset = card.center.x - cardViewAnchor.x
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let rotationDegree = (rotationAtMax / 5) * (xAxisOffset / halfViewWidth)
        guard firstFingerLocation != nil else { return }
        // Card's rotation direction is based on the finger position on the card
        let cardRotationRadian = (firstFingerLocation! == .upper) ? rotationDegree : -rotationDegree
        
        let velocity = sender.velocity(in: self.view) // points per second
        let releasePoint = CGPoint(x: card.frame.midX - cardViewAnchor.x, y: card.frame.midY - cardViewAnchor.y)
        let travelDistance = hypot(releasePoint.x, releasePoint.y)
        
        switch sender.state {
        case .began, .changed:
            // Disable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = false
            }
            
            // Card move to where the user's finger is
            card.center = CGPoint(x: cardViewAnchor.x + fingerMovement.x, y: cardViewAnchor.y + fingerMovement.y)
            
            // Card's rotation increase when it approaches the side edge of the screen
            card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
            
            // Set next card's transform based on current card's travel distance
            let distance = (travelDistance <= halfViewWidth) ? (travelDistance / halfViewWidth) : 1
            let transform = K.CardView.Size.transform
            let cardToTransform = (nextCard == .firstCard) ? firstCard : secondCard
            
            cardToTransform.transform = CGAffineTransform(
                scaleX: transform + (distance * (1 - transform)),
                y: transform + (distance * (1 - transform))
            )
            
        // When user's finger left the screen
        case .ended, .cancelled, .failed:
            firstFingerLocation = nil // reset finger location
            
            // Re-enable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = true
            }
            
            // Card dismissing threshold: a. Current card's data availability b. Velocity c. Travel distance
            let speed = hypot(velocity.x, velocity.y)
            let speedThreshold = K.CardView.Animation.Threshold.speed
            let distanceThreshold = K.CardView.Animation.Threshold.distance
            
            // The threshold to dismiss the current card view
            if currentData != nil && speed > speedThreshold && travelDistance > distanceThreshold {
                let endPoint = CGPoint(x: cardViewAnchor.x + velocity.x / 2, y: cardViewAnchor.y + velocity.y / 2)
                animateCard(card, to: endPoint)
                animateNextCardTransform()
                undoCard.data = currentData!
                
                self.displayToolbarTutorial() // Display toolbar tutorial
            }
            
            // Reset card's position and rotation state
            else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    card.transform = CGAffineTransform.identity
                    
                    // Bouncing effect
                    let offSet = CGPoint(x: -(releasePoint.x) / 8, y: -(releasePoint.y) / 8)
                    let bouncePoint = CGPoint(x: self.cardViewAnchor.x + offSet.x, y: self.cardViewAnchor.y + offSet.y)
                    card.center = bouncePoint
                    
                    // Reset the next card's transform
                    let transform = K.CardView.Size.transform
                    switch self.nextCard {
                    case .firstCard:
                        self.firstCard.transform = CGAffineTransform(scaleX: transform, y: transform)
                    case .secondCard:
                        self.secondCard.transform = CGAffineTransform(scaleX: transform, y: transform)
                    }
                } completion: { (bool) in
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
                        card.center = self.cardViewAnchor
                    }
                }
            }
        default:
            debugPrint("Error handling card panning detection.")
        }
    }
    
    private func animateCard(_ card: CardView, to endPoint: CGPoint) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            card.center = endPoint
            
        } completion: { (true) in
            // Save spawn position and transform of undo card
            self.undoCard.center = card.center
            self.undoCard.transform = card.transform
            
            self.removeGestureRecognizers(from: card)
            card.removeFromSuperview()
            
            switch self.currentCard {
            case .first:
                self.rotateCard(self.firstCard)
            case .second:
                self.rotateCard(self.secondCard)
            case .undo:
                // Enable the next card's gesture recognizers
                switch self.nextCard {
                case .firstCard:
                    self.attachGestureRecognizers(to: self.firstCard)
                    self.currentCard = .first
                    self.nextCard = .secondCard
                case .secondCard:
                    self.attachGestureRecognizers(to: self.secondCard)
                    self.currentCard = .second
                    self.nextCard = .firstCard
                }
            }
            self.refreshButtonState()
        }
    }
    
    //MARK: - Image Zooming and Panning Methods
    
    @objc private func handleImagePan(sender: UIPanGestureRecognizer) {
        if let view = sender.view {
            switch sender.state {
            case .began, .changed:
                // Get the touch position
                let translation = sender.translation(in: view)
                
                // Edit the center of the target by adding the gesture position
                let zoomRatio = view.frame.width / view.bounds.width
                view.center = CGPoint(
                    x: view.center.x + translation.x * zoomRatio,
                    y: view.center.y + translation.y * zoomRatio
                )
                sender.setTranslation(.zero, in: view)
                
            case .ended, .cancelled, .failed:
                // Reset card's position
                UIView.animate(withDuration: 0.4, animations: {
                    view.center = self.imageViewAnchor
                })
            default:
                debugPrint("Error handling image panning")
            }
        }
    }
    
    @objc private func handleImageZoom(sender: UIPinchGestureRecognizer) {
        if let view = sender.view {
            switch sender.state {
            case .began, .changed:
                // Coordinate of the pinch center where the view's center is (0, 0)
                let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                          y: sender.location(in: view).y - view.bounds.midY)
                let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                    .scaledBy(x: sender.scale, y: sender.scale)
                    .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                
                // Limit the minimum scale the card can be zoomed out
                view.transform = (view.frame.width >= view.bounds.width) ? transform : CGAffineTransform.identity
                sender.scale = 1
            case .ended, .cancelled, .failed:
                // Reset card's size
                UIView.animate(withDuration: 0.4, animations: {
                    view.transform = .identity
                })
            default:
                debugPrint("Error handling image zooming")
            }
        }
    }
    
    /// Reset the next card's transform with animation
    private func animateNextCardTransform() {
        UIView.animate(withDuration: 0.1) {
            switch self.nextCard {
            case .firstCard:
                self.firstCard.transform = .identity
            case .secondCard:
                self.secondCard.transform = .identity
            }
        }
    }
    
    private func attachGestureRecognizers(to card: CardView) {
        card.addGestureRecognizer(panCard)
        card.imageView.addGestureRecognizer(zoomImage)
        card.imageView.addGestureRecognizer(panImage)
    }
    
    private func removeGestureRecognizers(from card: CardView) {
        card.removeGestureRecognizer(panCard)
        card.imageView.removeGestureRecognizer(zoomImage)
        card.imageView.removeGestureRecognizer(panImage)
    }
    
    //MARK: - Error Handling Section
    
    /// Present error message to the user if any error occurs in the data fetching process
    func errorDidOccur() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Cannot connect to the Internet",
                message: "Signal from Cat Planet is too weak.\n Please check your antenna. 📡",
                preferredStyle: .alert)
            
            // Retry button which send network request to the network manager
            let retryAction = UIAlertAction(title: "Try Again", style: .default) { _ in
                self.networkManager.performRequest(numberOfRequests: K.Data.maxOfCachedData)
            }
            
            // Add actions to alert controller
            alert.addAction(retryAction)
            
            // Before presenting the alert view controller, ensure there's no existing one being presented already.
            if self.presentedViewController == nil {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension MainViewController: GADBannerViewDelegate {
    /// An ad request successfully receive an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1.0) {
            bannerView.alpha = 1
        }
    }
    
    /// Failed to receive ad with error.
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        debugPrint("adView: didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
