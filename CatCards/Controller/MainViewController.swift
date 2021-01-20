//
//  MainViewController.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import GoogleMobileAds
import UserNotifications
import AppTrackingTransparency

class MainViewController: UIViewController, NetworkManagerDelegate {
    
    //MARK: - IBOutlet
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarHeight: NSLayoutConstraint!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    @IBOutlet weak var bannerSpace: UIView!
    @IBOutlet weak var bannerSpaceHeight: NSLayoutConstraint!
    @IBOutlet weak var cardView: UIView!
    
    //MARK: - Global Properties
    
    private let defaults = UserDefaults.standard
    static let databaseManager = DatabaseManager()
    private let networkManager = NetworkManager()
    internal var cacheData: [Int: CatData] = [:]
    private var cardArray: [Card] = []
    private let undoCard = Card()
    private let onboardData = K.Onboard.data
    private var navBar: UINavigationBar!
    private lazy var cardViewAnchor = CGPoint()
//    private lazy var imageViewAnchor = CGPoint()
    private var cardIndex: Int = 0
    private var viewCount: Int = 0 // Number of cards with cat images the user has seen
//    private var currentCard: CurrentView = .first
//    private var nextCard: Card = .secondCard
    private var onboardCompleted = false
    private var adReceived = false
    private var backgroundLayer: CAGradientLayer!
    private var zoomOverlay: UIView!
    
    private var currentData: CatData? {
        if cardArray.count > cardIndex {
            return cardArray[cardIndex].data
        } else {
            return nil
        }
    }
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        pan.delegate = self
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        return pan
    }()
    
    private lazy var zoomGestureRecognizer: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoomHandler))
        pinch.delegate = self
        return pinch
    }()
    
    private lazy var twoFingerPanGestureRecognizer: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(twoFingerPanHandler))
        pan.delegate = self
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        return pan
    }()
    
    private lazy var adBannerView: GADBannerView = {
        // Initialize ad banner
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait) // Define ad banner's size
        adBannerView.adUnitID = K.Banner.adUnitID
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
//        currentCard = .first
        
        // Load viewCount value from UserDefaults if there's any
        let savedViewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        viewCount = (savedViewCount != 0) ? savedViewCount : 0
        
        // Notify this VC that if the app enters the background, save the cached view count value to UserDefaults.
        NotificationCenter.default.addObserver(self, selector: #selector(saveViewCount), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
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
        addGradientBackground() // Add gradient color layer to background
//        addShadeOverlay() // Add overlay view to be used when card is being zoomed in
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshButtonState()
        setBarStyle()
        
        // Load ad if status of loadBannerAd in user's device is true and no ad was received yet
        if defaults.bool(forKey: K.UserDefaultsKeys.loadBannerAd) && !adReceived {
            loadBannerAd()
        }
        
        // * CardView can only be added to the view after the height of the ad banner is known.
        if cardArray.count == 0 {
            createTwoCards()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get the default position of cardView and cardView's imageView after they're added to the view
        guard cardArray.count != 0 else { return }
        cardViewAnchor = (cardViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? cardArray[0].center : cardViewAnchor
//        imageViewAnchor = (imageViewAnchor == CGPoint(x: 0.0, y: 0.0)) ? cardArray[0].imageView.center : imageViewAnchor
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Reload the banner's ad if the orientation of the screen is about to change
        coordinator.animate { _ in
            self.loadBannerAd()
        }
    }
    
    // Remove notif. observer to avoid sending notification to invalid obj.
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    //MARK: - Background & Shading Control
    
    private func setBackgroundColor() {
        let interfaceStyle = traitCollection.userInterfaceStyle
        let lightModeColors = [K.Color.lightModeColor1, K.Color.lightModeColor2]
        let darkModeColors = [K.Color.darkModeColor1, K.Color.darkModeColor2]
        
        backgroundLayer.colors = (interfaceStyle == .light) ? lightModeColors : darkModeColors
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Make background color respond to change of interface style
        setBackgroundColor()
    }
    
    private func addGradientBackground() {
        backgroundLayer = CAGradientLayer()
        backgroundLayer.frame = view.bounds
        setBackgroundColor()
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    private func addShadeOverlay(below card: Card) {
        zoomOverlay = UIView(frame: view.bounds)
        zoomOverlay.backgroundColor = .black
        zoomOverlay.alpha = 0
        view.insertSubview(zoomOverlay, belowSubview: card)
    }
    
    //MARK: - Onboarding Methods
    
    /// Disable and hide button items in nav-bar and toolbar
    private func hideUIButtons() {
        // Hide navBar button
        navBar.tintColor = .clear
        collectionButton.isEnabled = false
        
        // Hide and disable toolbar buttons
        toolbar.alpha = 0
        shareButton.isEnabled = false
        undoButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    private func showUIButtons() {
        navBar.tintColor = K.Color.tintColor
        toolbar.alpha = 1
    }
    
    //MARK: - Advertisement Methods
    
    private func loadBannerAd() {
        // Request an ad for the adaptive ad banner.
        DispatchQueue.main.async {
            self.adBannerView.load(GADRequest())
        }
    }
    
    /// Place the banner at the center of the reserved ad space
    private func addBannerToBannerSpace(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerSpace.addSubview(bannerView)
        
        // Define center position only. Width and height is defined later.
        NSLayoutConstraint.activate([
            bannerView.centerYAnchor.constraint(equalTo: bannerSpace.centerYAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerSpace.centerXAnchor)
        ])
        
        // Banner's width equals the safe area's width
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
        
        // With adaptive banner, height of banner is based on the width of the banner itself
        // Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        // Set the height of the reserved ad space the same as the adaptive banner's height
        bannerSpaceHeight.constant = bannerView.frame.height
        
        UIView.animate(withDuration: 0.5) {
            self.updateLayout() // Animate the update of bannerSpace's height
        } completion: { _ in
//            self.cardViewAnchor = self.cardView.center // Update the card anchor
//            self.imageViewAnchor = self.cardView.center // Update the imageView anchor
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
    private func setBarStyle() {
        // Make background of navBar and toolbar transparent
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
    }
    
    //MARK: - Toolbar Button Method and State Control
    
    // Undo Action
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        guard undoCard.data != nil else { return }
        
        // Add undo card to view
        view.addSubview(undoCard)
        addCardViewConstraint(card: undoCard)
        // Update the content mode of the imageView in case the aspect ratio was changed by the addition of ad banner to the main view
        undoCard.data = cacheData[cardIndex - 3] // Import the last dismissed card's data
        undoButton.isEnabled = false
        
        UIView.animate(withDuration: 0.5) { // Introduction of undo card
            self.undoCard.center = self.cardViewAnchor
            self.undoCard.transform = .identity
            self.cardArray[0].transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.cardArray[1].transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { (true) in
            if true {
                self.attachGestureRecognizers(to: self.undoCard)
//                self.currentCard = .undo
                self.refreshButtonState()
            }
        }
        
//        // Remove current card's gesture recognizer and save its reference
//        switch currentCard {
//        case .first:
//            removeGestureRecognizers(from: cardArray[0])
//            nextCard = .firstCard
//        case .second:
//            removeGestureRecognizers(from: cardArray[1])
//            nextCard = .secondCard
//        case .undo:
//            debugPrint("Error: Undo button should have not been enabled")
//        }
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
    
    /// Update the toolbar buttons' status
    private func refreshButtonState() {
        guard onboardCompleted else { return } // Make sure the onboarding tutorial is completed.
        
        // Toggle the availability of toolbar buttons
        let dataIsLoaded = currentData != nil
        saveButton.isEnabled = dataIsLoaded ? true : false
        shareButton.isEnabled = dataIsLoaded ? true : false
//        undoButton.isEnabled = undoCard.data != nil && currentCard != .undo ? true : false
        
        // Toggle the status of favorite button
        if let data = currentData {
            let isDataSaved = MainViewController.databaseManager.isDataSaved(data: data)
            saveButton.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    //MARK: - Card Creation and Style
    
    /// Add two cardViews to the view and shrink the second card's size.
    private func createTwoCards() {
        if cardArray.isEmpty {
            // Initialize by adding two cards to the view first
            for _ in 0...1 {
                createNewCard() // Add two new cards to the view
            }
            if let firstCard = cardArray.first {
                attachGestureRecognizers(to: firstCard) // Bring the first card above the second card
                firstCard.transform = .identity // Reset transform
            }
        }
    }
    
    private func createNewCard() {
        let newCard = Card()
        newCard.tag = cardArray.count // Tag of card equals the index number of it in the card array
        
        if cardArray.isEmpty {
            cardView.addSubview(newCard)
        } else {
            // Place new card behind the last card in the array
//            cardView.insertSubview(newCard, belowSubview: cardArray.last!)
            cardView.addSubview(newCard)
            cardView.sendSubviewToBack(newCard)
        }
        addCardViewConstraint(card: newCard)
        
        if !onboardCompleted {
            newCard.setAsTutorialCard(cardIndex: newCard.tag)
        }
        
        newCard.data = cacheData[newCard.tag]
        cardArray.append(newCard)
        
        
        // Make the card smaller for it to reset the size when it's about to be shown to the user
        newCard.transform = CGAffineTransform(
            scaleX: K.CardView.Size.transform,
            y: K.CardView.Size.transform
        )
    }
    
    private func addCardViewConstraint(card: Card) {
        let centerXAnchor = card.centerXAnchor.constraint(equalTo: cardView.centerXAnchor)
        let centerYAnchor = card.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        let heightAnchor = card.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.95)
        let widthAnchor = card.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.95)
        
        // Save constraints to the card's property for manipulation in the future
        card.centerX = centerXAnchor
        card.centerY = centerYAnchor
        card.height = heightAnchor
        card.width = widthAnchor
        
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.centerX, card.centerY, card.height, card.width
        ])
    }
    
    //MARK: - Data Fetching & Handling
    
    private func fetchNewData(initialRequest: Bool) {
        switch initialRequest {
        case true:
            networkManager.performRequest(numberOfRequests: K.Data.cacheDataNumber)
        case false:
            networkManager.performRequest(numberOfRequests: 1)
        }
    }
    
    // Update UI when new data is downloaded succesfully
    func dataDidFetch(data: CatData, index: Int) {
        // Store newly fetched data
        cacheData[index] = data
        
        if index == cardIndex || index == cardIndex + 1 {
            // Update the current and the next card's data
            cardArray[index].data = data
        }
        
        // Maintain the maximum number of cache data
        let maxCacheNumber = K.Data.cacheDataNumber
        let maxUndoNumber = K.Data.undoCardNumber
        
        if cacheData.count > maxCacheNumber + maxUndoNumber {
            if let cacheDataFirstKey = cacheData.keys.sorted().first {
                cacheData[cacheDataFirstKey] = nil
            }
        }
        print("cacheData count: \(cacheData.count)")
    }
    
    //MARK: - Gesture Recognizers
    
    private enum Side {
        case upper, lower
    }
    
    private var firstFingerLocation: Side?
    
    var startingCenterX: CGFloat = 0
    var startingCenterY: CGFloat = 0
    var startingTransform: CGAffineTransform = .identity
    
    /// Handling the cardView's panning effect which is responded to user's input via finger dragging on the cardView itself.
    /// - Parameter sender: A concrete subclass of UIGestureRecognizer that looks for panning (dragging) gestures.
    @objc private func panHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        let nextCard = cardArray[cardIndex + 1]
        
        let halfViewWidth = view.frame.width / 2
        
        // Point of the finger in the view's coordinate system
        let fingerPosition = sender.location(in: sender.view)
        let side: Side = fingerPosition.y < card.frame.midY ? .upper : .lower
        // Save which side of the card the finger is placed
        firstFingerLocation = (firstFingerLocation == nil) ? side : firstFingerLocation
        
        let translation = sender.translation(in: view)
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisOffset = card.centerX.constant
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let rotationDegree = (rotationAtMax / 5) * (xAxisOffset / halfViewWidth)
        guard firstFingerLocation != nil else { return }
        // Card's rotation direction is based on the finger position on the card
        let cardRotationRadian = (firstFingerLocation! == .upper) ? rotationDegree : -rotationDegree
        let velocity = sender.velocity(in: self.view) // points per second
        
        // Card's offset of x and y position
        let offset = CGPoint(x: card.centerX.constant, y: card.centerY.constant)
        
        // Distance of card's center to its origin point
        let panDistance = hypot(offset.x, offset.y)
        
        switch sender.state {
        case .began:
            startingCenterX = card.centerX.constant
            startingCenterY = card.centerY.constant
            startingTransform = card.transform
        case .changed:
            // Card move to where the user's finger is
            card.centerX.constant = startingCenterX + translation.x
            card.centerY.constant = startingCenterY + translation.y
            updateLayout()
            
            // Card's rotation increase when it approaches the side edge of the screen
            card.transform = startingTransform.concatenating(CGAffineTransform(rotationAngle: cardRotationRadian))
            
            // Set next card's transform based on current card's travel distance
            let distance = (panDistance <= halfViewWidth) ? (panDistance / halfViewWidth) : 1
            let transform = K.CardView.Size.transform
            
            nextCard.transform = CGAffineTransform(
                scaleX: transform + (distance * (1 - transform)),
                y: transform + (distance * (1 - transform))
            )
            
        // When user's finger left the screen
        case .ended, .cancelled, .failed:
            firstFingerLocation = nil // Reset first finger location
            
            let minTravelDistance = view.frame.height // minimum travel distance of the card
            let minDragDistance = halfViewWidth // minimum dragging distance of the card
            let vector = CGPoint(x: velocity.x / 2, y: velocity.y / 2)
            let vectorDistance = hypot(vector.x, vector.y)
            
            let distanceDelta = minTravelDistance / panDistance
            let minimumDelta = CGPoint(x: offset.x * distanceDelta,
                                     y: offset.y * distanceDelta)
            
            if currentData != nil &&
                vectorDistance >= minTravelDistance {
                // Card dismissing threshold A: Data is available and
                // the projected travel distance is greater than or equals minimum distance
                animateCard(card, deltaX: vector.x, deltaY: vector.y)
            }
            else if currentData != nil &&
                        vectorDistance < minTravelDistance &&
                        panDistance >= minDragDistance {
                // Card dismissing thrshold B: Data is available and
                // the projected travel distance is less than the minimum travel distance
                // but the distance of card being dragged is greater than distance threshold
                animateCard(card, deltaX: minimumDelta.x, deltaY: minimumDelta.y)
            }
            
            // Reset card's position and rotation state
            else {
                // Bouncing effect
                let bounceVector = CGPoint(x: -(offset.x) / 8, y: -(offset.y) / 8)
                card.centerX.constant = startingCenterX + bounceVector.x
                card.centerY.constant = startingCenterY + bounceVector.y
                
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    self.updateLayout()
                    card.transform = self.startingTransform
                    
                    // Reset the next card's transform
                    let transformScale = K.CardView.Size.transform
                    nextCard.transform = CGAffineTransform(scaleX: transformScale, y: transformScale)
                } completion: { (bool) in
                    card.centerX.constant = self.startingCenterX
                    card.centerY.constant = self.startingCenterY
                    
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
                        self.updateLayout()
                    }
                }
            }
        default:
            debugPrint("Error handling card panning detection.")
        }
    }
    
    @objc private func twoFingerPanHandler(sender: UIPanGestureRecognizer) {
        if let card = sender.view as? Card {
            switch sender.state {
            case .began:
                startingCenterX = card.centerX.constant
                startingCenterY = card.centerY.constant
            case .changed:
                // Get the touch position
                let translation = sender.translation(in: card)
                
                // Card move to where the user's finger is
                let zoomRatio = view.frame.width / view.bounds.width
                card.centerX.constant = startingCenterX + translation.x * zoomRatio
                card.centerY.constant = startingCenterY + translation.y * zoomRatio
                updateLayout()
                
            case .ended, .cancelled, .failed:
                // Move card back to original position
                card.centerX.constant = startingCenterX
                card.centerY.constant = startingCenterY
                UIView.animate(withDuration: 0.35, animations: {
                    self.updateLayout()
                })
            default:
                debugPrint("Error handling image panning")
            }
        }
    }
    
    @objc private func zoomHandler(sender: UIPinchGestureRecognizer) {
        if let card = sender.view as? Card {
            switch sender.state {
            case .began:
                startingCenterX = card.centerX.constant
                startingCenterY = card.centerY.constant
                startingTransform = card.transform
                
                // Create and place overlay behind current card
//                addShadeOverlay(below: card)
            case .changed:
                // Coordinate of the pinch center where the view's center is (0, 0)
                let pinchCenter = CGPoint(
                    x: sender.location(in: card).x - card.bounds.midX,
                    y: sender.location(in: card).y - card.bounds.midY)
                
                // Card transform behavior
                // Move the card to the opposite point of the pinch center if the scale delta > 1, vice versa
                let transform = card.transform.translatedBy(
                    x: pinchCenter.x, y: pinchCenter.y)
                    .scaledBy(x: sender.scale, y: sender.scale)
                    .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                
                // Limit the minimum size the card can be scaled
                let newWidth = sender.scale * card.frame.width
                let minimumWidth = card.bounds.width
                if newWidth > minimumWidth {
                    card.transform = startingTransform.concatenating(transform)
                }
                sender.scale = 1
                
//                // Increase opacity of the overlay view as the card is enlarged
//                let originalWidth = card.bounds.width
//                let currentWidth = card.frame.width
//                let maxOpacity: CGFloat = 0.6 // max opacity of the overlay view
//                let cardWidthDelta = (currentWidth / originalWidth) - 1 // Percentage change of width
//                let deltaToMaxOpacity: CGFloat = 0.2 // number of width delta to get maximum opacity
                    
//                zoomOverlay.alpha = maxOpacity * min((cardWidthDelta / deltaToMaxOpacity), 1.0)
                
//                // Hide navBar button
//                UIView.animate(withDuration: 0.3) {
//                    self.collectionButton.tintColor = .clear
//                }
            
            case .ended, .cancelled, .failed:
                // Reset card's size
                UIView.animate(withDuration: 0.35, animations: {
                    card.transform = self.startingTransform
//                    self.zoomOverlay.alpha = 0
                }) { _ in
//                    self.collectionButton.tintColor = K.Color.tintColor
//                    self.zoomOverlay.removeFromSuperview()
                }
            default:
                debugPrint("Error handling image zooming")
            }
        }
    }
    
    private func attachGestureRecognizers(to card: UIView) {
        card.addGestureRecognizer(panGestureRecognizer)
        card.addGestureRecognizer(zoomGestureRecognizer)
        card.addGestureRecognizer(twoFingerPanGestureRecognizer)
    }
    
    private func removeGestureRecognizers(from card: Card) {
        card.removeGestureRecognizer(panGestureRecognizer)
        card.removeGestureRecognizer(zoomGestureRecognizer)
        card.removeGestureRecognizer(twoFingerPanGestureRecognizer)
    }
    
    //MARK: - Animation Methods
    
    private func animateCard(_ card: Card, deltaX: CGFloat, deltaY: CGFloat) {
        updateCardConstraints(card: card, deltaX: deltaX, deltaY: deltaY)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.updateLayout()
            self.resetNextCardTransform()
        } completion: { _ in
            self.cardIndex += 1
            self.attachGestureRecognizers(to: self.cardArray[self.cardIndex])
            
            self.createNewCard()
            self.fetchNewData(initialRequest: false)
            
//            card.removeFromSuperview()
            
            card.data = nil // Clear the memory used by the imageViews of the card
            
            print("card array counts: \(self.cardArray.count)")
//            self.refreshButtonState()
        }
    }
    
    private func removeDismissedCard() {
        if cardArray.count > 2 + K.Data.undoCardNumber {
            cardArray.first?.removeFromSuperview()
        }
    }
    
    /// Reset the next card's transform with animation
    private func resetNextCardTransform() {
        cardArray[cardIndex + 1].transform = .identity
    }
    
    private func updateCardConstraints(card: Card, deltaX: CGFloat, deltaY: CGFloat) {
        card.centerX.constant += deltaX
        card.centerY.constant += deltaY
    }
    
    private func updateLayout() {
        self.view.layoutIfNeeded()
    }
    
    //MARK: - Cards Rotation & Image Updating
    
//    private func rotateCard(_ card: Card) {
//        nextCard = (card == cardArray[0]) ? .firstCard : .secondCard
//        currentCard = (nextCard == .firstCard) ? .second : .first
//
//        card.data = nil // Trigger method reloadImageData in class CardView
//        let currentCard = (self.currentCard == .first) ? cardArray[0] : cardArray[1]
//        attachGestureRecognizers(to: currentCard)
//
//        // Put the dismissed card behind the current card
//        self.view.insertSubview(card, belowSubview: currentCard)
//        card.center = cardViewAnchor
//        addCardViewConstraint(card: card)
//
//        // Shrink the size of the newly added card view
//        card.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
//
//        // Show toolbar buttons after the second tutorial card is dismissed
//        if !onboardCompleted && cardIndex == 3 {
//            UIView.animate(withDuration: 0.5) {
//                self.showUIButtons()
//            }
//        }
//
//        // Enable all UI buttons after the last tutorial card is dismissed
//        if cardIndex > onboardData.count && !onboardCompleted {
//            onboardCompleted = true
//            collectionButton.isEnabled = true
//
//            // Save onboardCompleted status to true in User Defaults
//            defaults.setValue(true, forKey: K.UserDefaultsKeys.onboardCompleted)
//        }
//
//        // Update the count of view the user has seen if the current card's data is valid
//        if currentData != nil && onboardCompleted {
//            viewCount += 1
//
//            // This method is put here to avoid the cardView dismissing issue where
//            // the card dismissing destination might be disrupted if the constraints on view changed when
//            // the dismissing animation is still executing at the same time.
//            // If this issue is solved in the future, consider move this method
//            // to a place which makes more sense.
//
//            // Load banner ad if user has viewed certain number of cat images and the ad has yet to be loaded.
//            if viewCount >= K.Banner.adLoadingThreshold && !adReceived {
//                if #available(iOS 14, *),
//                   ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
//                    // This method is available in iOS 14 and later
//                    // User's permission is required to get device's identifier for advertising
//                    requestIDFA()
//                } else {
//                    loadBannerAd()
//                }
//                // Load banner ad automatically after the app is lauched next time
//                defaults.setValue(true, forKey: K.UserDefaultsKeys.loadBannerAd)
//            }
//        }
//
//        updateCardView()
//        fetchNewData(initialRequest: false)
//    }
    
    /// Update card's content if new data is available.
//    private func updateCardView() {
//        let dataAllocation: Card = (cardIndex % 2 == 0) ? .firstCard : .secondCard
//
//        if let newData = cacheData[cardIndex] { // Make sure new data is available
//            switch dataAllocation { // Decide which card the data is to be allocated
//            case .firstCard:
//                cardArray[0].data = newData // Update card's data
//
//                // Show tutorial text on this card if there's still tutorial to be shown
//                if !onboardCompleted && cardIndex < onboardData.count {
//                    cardArray[0].setAsTutorialCard(cardIndex: cardIndex)
//                }
//                cardIndex += 1
//            case .secondCard:
//                cardArray[1].data = newData  // Update card's data
//
//                // Show tutorial text on this card if there's still tutorial to be shown
//                if !onboardCompleted && cardIndex < onboardData.count {
//                    cardArray[1].setAsTutorialCard(cardIndex: cardIndex)
//                }
//                cardIndex += 1
//            }
//
//            // Increment the view count if card's data was unavailable but now updated
//            if currentData == nil {
//                self.viewCount += 1
//            }
//        }
//
//        DispatchQueue.main.async {
//            self.refreshButtonState()
//        }
//    }
    
    //MARK: - Error Handling Section
    
    /// Present error message to the user if any error occurs in the data fetching process
    func networkErrorDidOccur() {
        // Make sure there's no existing alert controller being presented already.
        guard self.presentedViewController == nil else { return }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: Z.AlertMessage.NetworkError.alertTitle,
                message: Z.AlertMessage.NetworkError.alertMessage,
                preferredStyle: .alert)
            
            // Retry button which send network request to the network manager
            let retryAction = UIAlertAction(title: Z.AlertMessage.NetworkError.actionTitle, style: .default) { _ in
                let requestNumber = K.Data.cacheDataNumber - self.cacheData.count
                self.networkManager.performRequest(numberOfRequests: requestNumber)
            }
            
            // Add actions to alert controller
            alert.addAction(retryAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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

extension MainViewController: GADBannerViewDelegate {
    /// An ad request successfully receive an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        addBannerToBannerSpace(adBannerView)
        
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
