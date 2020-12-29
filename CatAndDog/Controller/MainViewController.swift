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
import AppTrackingTransparency

private enum Card {
    case firstCard, secondCard
}

private enum CurrentView {
    case first, second, undo
}

class MainViewController: UIViewController, NetworkManagerDelegate {
    
    //MARK: - IBOutlet
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarHeight: NSLayoutConstraint!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var bannerSpace: UIView!
    @IBOutlet weak var bannerSpaceHeight: NSLayoutConstraint!
    @IBOutlet weak var goToCollectionViewBtn: UIBarButtonItem!
    
    //MARK: - Global Properties
    
    static let databaseManager = DatabaseManager()
    private let networkManager = NetworkManager()
    private let defaults = UserDefaults.standard
    private let firstCard = CardView()
    private let secondCard = CardView()
    private let undoCard = CardView()
    private let onboardData = K.Onboard.data
    private var navBar: UINavigationBar!
    private lazy var cardViewAnchor = CGPoint()
    private lazy var imageViewAnchor = CGPoint()
    private var dataIndex: Int = 0
    private var viewCount: Int = 0 // Number of cards with cat images the user has seen
    private var currentCard: CurrentView = .first
    private var nextCard: Card = .secondCard
    private var cardsAreAddedToView = false
    private var onboardCompleted = false
    private var adReceived = false
    
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
        
        navBar = self.navigationController?.navigationBar // Save the reference of the built-in navigation bar
        MainViewController.databaseManager.delegate = self
        networkManager.delegate = self
        currentCard = .first
        
        // Load viewCount value from UserDefaults if there's any
        let savedViewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        viewCount = (savedViewCount != 0) ? savedViewCount : 0
        
        // Notify this VC that if the app enters the background, save the cached view count value to UserDefaults.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(saveViewCount),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        // Show onboarding tutorial and hide toolbar if the user is a new comer
        onboardCompleted = defaults.bool(forKey: K.UserDefaultsKeys.onboardCompleted)
        if !onboardCompleted {
            hideUIButtons()
        }
        
        // Create local image folder in file system and/or load data from it
        MainViewController.databaseManager.createDirectory()
        MainViewController.databaseManager.getSavedImageFileURLs()
        
        fetchNewData(initialRequest: true) // initiate data downloading
        
        setDownsampleSize() // Prepare ImageProcess's operation parameter
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshButtonState()
        hideUIHairlines()
        
        // Load ad if status of loadBannerAd in user's device is true and no ad was received yet
        if defaults.bool(forKey: K.UserDefaultsKeys.loadBannerAd) && !adReceived {
            addBannerToView(adBannerView)
            loadBannerAd()
        }
        
        // * CardView can only be added to the view after the height of the ad banner is known.
        if !cardsAreAddedToView {
            addCardsToView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get the default position of cardView and cardView's imageView after they're added to the view
        cardViewAnchor = (cardViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? firstCard.center : cardViewAnchor
        imageViewAnchor = (imageViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? firstCard.imageView.center : imageViewAnchor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navBar.setBackgroundImage(nil, for: .default) // Un-hidden nav bar's hairline
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Reload the banner's ad if the orientation of the screen is about to change
        coordinator.animate { _ in
            self.loadBannerAd()
        }
    }
    
    //MARK: - Onboarding Methods
    
    /// Disable and hide button items in nav-bar and toolbar
    private func hideUIButtons() {
        // Hide navBar button
        navBar.tintColor = K.Color.backgroundColor
        goToCollectionViewBtn.isEnabled = false
        
        // Hide toolbar buttons
        toolbar.alpha = 0
        shareButton.isEnabled = false
        undoButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    private func showUIButtons() {
        navBar.tintColor = K.Color.tintColor
        toolbar.alpha = 1
    }
     
    private func animateFirstCard() {
        let anchorPoint = self.firstCard.center
        
        // Shake the first card to hint the user how swiping gesture works
        UIView.animate(withDuration: 0.25, delay: 1.0) {
            // Move and rotate the first card to the right
            self.firstCard.transform = CGAffineTransform(rotationAngle: 0.1)
            self.firstCard.center = CGPoint(x: anchorPoint.x + 20, y: anchorPoint.y)
        } completion: { _ in
            // Move and rotate the first card to the left
            UIView.animate(withDuration: 0.25) {
                self.firstCard.transform = CGAffineTransform(rotationAngle: -0.1)
                self.firstCard.center = CGPoint(x: anchorPoint.x - 20, y: anchorPoint.y)
            } completion: { _ in
                // Rotate the first card back to original position
                UIView.animate(withDuration: 0.25) {
                    self.firstCard.transform = .identity
                    self.firstCard.center = anchorPoint
                } completion: { _ in
                    self.attachGestureRecognizers(to: self.firstCard)
                }
            }
        }
    }
    
    //MARK: - Advertisement Methods
    
    private func loadBannerAd() {
        // Request an ad for the adaptive ad banner.
        DispatchQueue.main.async {
            self.adBannerView.load(GADRequest())
        }
    }
    
    /// Place the banner at the center of the reserved ad space
    private func addBannerToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerSpace.addSubview(bannerView)
        
        // Note that the size of the adaptive ad banner is returned by Google,
        // therefore defining height or width here is not necessary.
        NSLayoutConstraint.activate([
            bannerView.centerYAnchor.constraint(equalTo: bannerSpace.centerYAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerSpace.centerXAnchor)
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
        bannerSpaceHeight.constant = bannerView.frame.height
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded() // Animate the update of bannerSpace's height
        } completion: { _ in
            self.cardViewAnchor = self.firstCard.center // Update the card anchor
            self.imageViewAnchor = self.firstCard.imageView.center // Update the imageView anchor
        }
        
    }
    
    /// Google recommend waiting for the completion callback prior to loading ads,
    /// so that if the user grants the App Tracking Transparency permission,
    /// the Google Mobile Ads SDK can use the IDFA in ad requests.
    @available(iOS 14, *)
    private func requestIDFA() {
        ATTrackingManager.requestTrackingAuthorization { (status) in
            // Tracking authorization completed. Start loading ads here.
            self.loadBannerAd()
        }
    }
    
    //MARK: - Support Methods
    
    /// Save the value of card view count to user defaults
    @objc func saveViewCount() {
        defaults.setValue(viewCount, forKey: K.UserDefaultsKeys.viewCount)
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
        MainViewController.databaseManager.imageProcess.cellSize = cellSize
    }
    
    /// Hide navigation bar and toolbar's border line
    private func hideUIHairlines() {
        // Hide navigation bar's border line
        navBar.isTranslucent = false
        navBar.barTintColor = K.Color.backgroundColor
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        
        // Hide toolbar's hairline
        self.toolbar.clipsToBounds = true
        self.toolbar.barTintColor = K.Color.backgroundColor
        self.toolbar.isTranslucent = false
    }
    
    //MARK: - Toolbar Button Method and State Control
    
    /// Update the toolbar buttons' status
    private func refreshButtonState() {
        guard onboardCompleted else { return } // Make sure the onboarding tutorial is completed.
        
        // Toggle the availability of toolbar buttons
        let dataIsLoaded = currentData != nil
        saveButton.isEnabled = dataIsLoaded ? true : false
        shareButton.isEnabled = dataIsLoaded ? true : false
        undoButton.isEnabled = undoCard.data != nil && currentCard != .undo ? true : false
        
        // Toggle the status of favorite button
        if let data = currentData {
            let isDataSaved = MainViewController.databaseManager.isDataSaved(data: data)
            saveButton.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    // Undo Action
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        guard undoCard.data != nil else { return }
        // Update the content mode of the imageView in case the aspect ratio was changed by the addition of ad banner to the main view
        undoCard.data = undoCard.data
        self.undoButton.isEnabled = false
        
        // Remove current card's gesture recognizer and save its reference
        switch currentCard {
        case .first:
            removeGestureRecognizers(from: firstCard)
            nextCard = .firstCard
        case .second:
            removeGestureRecognizers(from: secondCard)
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
            // Save data if it's absent in database, otherwise delete it.
            let isDataSaved = MainViewController.databaseManager.isDataSaved(data: data)
            switch isDataSaved {
            case false:
                MainViewController.databaseManager.saveData(data)
            case true:
                MainViewController.databaseManager.deleteData(id: data.id)
            }
            refreshButtonState()
        }
    }
    
    // Image Sharing Method
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        if let imageToShare = currentData?.image {
            let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
            present(activityController, animated: true)
        }
    }
    
    //MARK: - Card Creation and Style
    
    /// Add two cardViews to the view and shrink the second card's size.
    private func addCardsToView() {
        view.addSubview(firstCard)
        view.insertSubview(secondCard, belowSubview: firstCard)
        
        addCardViewConstraint(card: firstCard)
        addCardViewConstraint(card: secondCard)
        secondCard.transform = CGAffineTransform(scaleX: K.CardView.Size.transform,
                                                 y: K.CardView.Size.transform)
        
        cardsAreAddedToView = true
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
                equalTo: self.toolbar.topAnchor,
                constant: K.CardView.Constraint.bottom)
        ])
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
    func dataDidFetch() {
        let dataSet = networkManager.serializedData
        
        // Update image, buttons and attach gesture recognizers
        switch dataIndex {
        case 0:
            if let firstData = dataSet[dataIndex] {
                firstCard.data = firstData
                
                if !onboardCompleted && dataIndex == 0 {
                    firstCard.setAsTutorialCard(cardIndex: 0)
                    DispatchQueue.main.async {
                        self.animateFirstCard()
                    }
                } else {
                    viewCount += 1 // Increment the number of cat the user has seen
                    DispatchQueue.main.async {
                        self.refreshButtonState() // Refresh toolbar buttons' state
                        self.attachGestureRecognizers(to: self.firstCard) // Add gesture recognizer to first card
                    }
                }
                
                dataIndex += 1
            }
        case 1:
            if let secondData = dataSet[dataIndex] {
                secondCard.data = secondData
                
                if !onboardCompleted {
                    secondCard.setAsTutorialCard(cardIndex: 1)
                }
                
                dataIndex += 1
            }
        default:
            // Update either cardView if its data is not available
            if firstCard.data == nil || secondCard.data == nil {
                updateCardView()
            }
        }
    }
    
    //MARK: - Cards Rotation Section
    
    private func rotateCard(_ card: CardView) {
        nextCard = (card == firstCard) ? .firstCard : .secondCard
        self.currentCard = (nextCard == .firstCard) ? .second : .first
        
        card.data = nil // Trigger method reloadImageData in class CardView 
        let currentCard = (self.currentCard == .first) ? firstCard : secondCard
        attachGestureRecognizers(to: currentCard)
        
        // Put the dismissed card behind the current card
        self.view.insertSubview(card, belowSubview: currentCard)
        card.center = cardViewAnchor
        addCardViewConstraint(card: card)
        
        // Shrink the size of the newly added card view
        card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        // Show toolbar buttons after the first tutorial card is dismissed
        if !onboardCompleted && dataIndex == 2 {
            UIView.animate(withDuration: 0.5) {
                self.showUIButtons()
            }
        }
        
        // Enable all UI buttons after the last tutorial card is dismissed
        if dataIndex > onboardData.count && !onboardCompleted {
            onboardCompleted = true
            goToCollectionViewBtn.isEnabled = true
            
            // Save onboardCompleted status to true in User Defaults
            defaults.setValue(true, forKey: K.UserDefaultsKeys.onboardCompleted)
        }
        
        // Update the count of view the user has seen if the current card's data is valid
        if currentData != nil && onboardCompleted {
            viewCount += 1
        
            // This method is put here to avoid the cardView dismissing issue where
            // the card dismissing destination might be disrupted if the constraints on view changed when
            // the dismissing animation is still executing at the same time.
            // If this issue is solved in the future, consider move this method
            // to a place which makes more sense.
            
            // Load banner ad if user has viewed certain number of cat images and the ad has yet to be loaded.
            if viewCount >= K.Banner.cardViewedToLoadBannerAd && !adReceived {
                addBannerToView(adBannerView)
                if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                    // This method is available in iOS 14 and later
                    // User's permission is required to get device's identifier for advertising
                    requestIDFA()
                } else {
                    loadBannerAd()
                }
                defaults.setValue(true, forKey: K.UserDefaultsKeys.loadBannerAd) // Save default status to true
            }
        }
        
        updateCardView()
        fetchNewData(initialRequest: false)
    }
    
    //MARK: - Update Image of imageView
    
    /// Update card's content if new data is available.
    private func updateCardView() {
        let dataSet = networkManager.serializedData
        let dataAllocation: Card = ((self.dataIndex) % 2 == 1) ? .secondCard : .firstCard
        
        if let newData = dataSet[dataIndex] { // Make sure new data is available
            switch dataAllocation { // Decide which card the data is to be allocated
            case .firstCard:
                firstCard.data = newData // Update card's data
                
                // Show tutorial text on this card if there's still tutorial to be shown
                if !onboardCompleted && dataIndex < onboardData.count {
                    firstCard.setAsTutorialCard(cardIndex: dataIndex)
                }
                dataIndex += 1
            case .secondCard:
                secondCard.data = newData  // Update card's data
                
                // Show tutorial text on this card if there's still tutorial to be shown
                if !onboardCompleted && dataIndex < onboardData.count {
                    secondCard.setAsTutorialCard(cardIndex: dataIndex)
                }
                dataIndex += 1
            }
            
            // Increment the view count if card's data was invalid but updated
            if currentData == nil {
                self.viewCount += 1
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
        
        // Point of the card relative to the center point
        let releasePoint = CGPoint(x: card.frame.midX - cardViewAnchor.x,
                                   y: card.frame.midY - cardViewAnchor.y)
        // Distance of card's center to its origin point
        let panDistance = hypot(releasePoint.x, releasePoint.y)
        
        switch sender.state {
        case .began, .changed:
            // Disable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = false
            }
            
            // Card move to where the user's finger is
            card.center = CGPoint(x: cardViewAnchor.x + fingerMovement.x,
                                  y: cardViewAnchor.y + fingerMovement.y)
            
            // Card's rotation increase when it approaches the side edge of the screen
            card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
            
            // Set next card's transform based on current card's travel distance
            let distance = (panDistance <= halfViewWidth) ? (panDistance / halfViewWidth) : 1
            let transform = K.CardView.Size.transform
            let cardToTransform = (nextCard == .firstCard) ? firstCard : secondCard
            
            cardToTransform.transform = CGAffineTransform(
                scaleX: transform + (distance * (1 - transform)),
                y: transform + (distance * (1 - transform))
            )
            
        // When user's finger left the screen
        case .ended, .cancelled, .failed:
            firstFingerLocation = nil // Reset first finger location
            
            // Re-enable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = true
            }
            
            let minTravelDistance = view.frame.height // minimum travel distance of the card
            let minDragDistance = halfViewWidth // minimum dragging distance of the card
            let momentum = CGPoint(x: velocity.x / 2, y: velocity.y / 2)
            
            let projectedPoint = CGPoint(x: cardViewAnchor.x + momentum.x,
                                           y: cardViewAnchor.y + momentum.y)
            let projectedDistance = hypot(projectedPoint.x - cardViewAnchor.x,
                                           projectedPoint.y - cardViewAnchor.y)
            
            let distanceDelta = minTravelDistance / panDistance
            let pointDelta = CGPoint(x: releasePoint.x * distanceDelta,
                                     y: releasePoint.y * distanceDelta)
            let minimumVelocityEndpoint = CGPoint(
                x: cardViewAnchor.x + pointDelta.x,
                y: cardViewAnchor.y + pointDelta.y)
            
            if currentData != nil && projectedDistance >= minTravelDistance {
                // Card dismissing threshold A: Data is available and
                // the projected travel distance is greater than or equals minimum distance
                animateCard(card, to: projectedPoint)
                animateNextCardTransform()
            }
            else if currentData != nil && projectedDistance < minTravelDistance && panDistance > minDragDistance {
                // Card dismissing thrshold B: Data is available and
                // the projected travel distance is less than the minimum travel distance
                // and the card dragged distance is greater than distance threshold
                animateCard(card, to: minimumVelocityEndpoint)
                animateNextCardTransform()
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
            
        } completion: { _ in
            // Save spawn position and transform of undo card
            self.undoCard.data = self.currentData!
            self.undoCard.center = card.center
            self.undoCard.transform = card.transform
            
            self.removeGestureRecognizers(from: card)
            card.removeFromSuperview()
            
            switch self.currentCard {
            case .first, .second:
                self.rotateCard(card)
            case .undo:
                // Enable the next card's gesture recognizers and update card status
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
                // Move imageView back to default position
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
    func networkErrorDidOccur() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: Z.AlertMessage.NetworkError.alertTitle,
                message: Z.AlertMessage.NetworkError.alertMessage,
                preferredStyle: .alert)
            
            // Retry button which send network request to the network manager
            let retryAction = UIAlertAction(title: Z.AlertMessage.NetworkError.actionTitle, style: .default) { _ in
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
    
    // TEST USE
    @IBAction func resetButtonPressed(_ sender: UIBarButtonItem) {
        // Reset all default setting
        defaults.setValue(false, forKey: K.UserDefaultsKeys.onboardCompleted)
        defaults.setValue(false, forKey: K.UserDefaultsKeys.loadBannerAd)
        defaults.setValue((0), forKey: K.UserDefaultsKeys.viewCount)
    }
    
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MainViewController: GADBannerViewDelegate {
    /// An ad request successfully receive an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1.0) {
            bannerView.alpha = 1
        }
        self.adReceived = true
    }
    
    /// Failed to receive ad with error.
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        debugPrint("adView: didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}

extension MainViewController: DatabaseManagerDelegate {
    /// Number of saved images has reached the limit.
    func savedImagesMaxReached() {
        // Show alert to the user
        let alert = UIAlertController(title: Z.AlertMessage.DatabaseError.alertTitle,
                                      message: Z.AlertMessage.DatabaseError.alertMessage,
                                      preferredStyle: .alert)
        let acknowledgeAction = UIAlertAction(title: Z.AlertMessage.DatabaseError.actionTitle,
                                              style: .cancel)
        alert.addAction(acknowledgeAction)
        
        present(alert, animated: true, completion: nil)
    }
}
