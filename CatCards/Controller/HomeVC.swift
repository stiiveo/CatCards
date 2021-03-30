//
//  HomeVC.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit
import GoogleMobileAds
import UserNotifications
import AppTrackingTransparency

class HomeVC: UIViewController, APIManagerDelegate {
    
    //MARK: - IBOutlet
    
    // Access point to this view's built–in toolbar.
    @IBOutlet weak var toolbar: UIToolbar!
    
    // A button which saves the current card's image to the device's app folder with attribute info being saved to database via CoreData.
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // A button which allows user to share current card's image.
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    // A button which retrieves previously dismissed card back to the top layer of the card view.
    @IBOutlet weak var undoButton: UIBarButtonItem!
    
    // A button which triggers segue from HomeVC to CollectionVC.
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    
    // A reserved space used to accommodate the banner view.
    @IBOutlet weak var bannerSpace: UIView!
    
    // Modifying the banner space's height to accommodate the adaptive bannerView once the its height is determined.
    @IBOutlet weak var bannerSpaceHeight: NSLayoutConstraint!
    
    // Super view to which all cards being added.
    @IBOutlet weak var cardView: UIView!
    
    //MARK: - Local Properties
    
    static let shared = HomeVC()
    private let defaults = UserDefaults.standard
    private let dbManager = DatabaseManager.shared
    
    // Cache of all Card objects used to display to the user.
    private var cardArray: [Int: Card] = [:]
    
    // Array of string data used as the content of the onboard info.
    private let onboardData = K.OnboardOverlay.data
    
    // Navigational bar this view controller provides.
    private var navBar: UINavigationBar!
    
    // The pointer to which card being added to the top layer of the cardView.
    private var pointer: Int = 0
    
    // Maximum number of cards with different data shown to the user.
    private var maxPointerReached: Int = 0
    
    // Indicator on if any banner ad is received from GoogleMobileAds API.
    private var adReceived = false
    
    // Background view behind the main imageView.
    private var backgroundLayer: CAGradientLayer!
    
    // A shading layer displayed behind the current card when the current card is zoomed–in by the user.
    private var zoomOverlay: UIView!
    
    // Indicator on whether the current card is being panned.
    private var cardIsBeingPanned = false
    
    // Haptic manager which manages customized operation of the device's haptic engine.
    private let hapticManager = HapticManager()
    
    // Indicator on whether to display overlay over the card.
    var showOverlay = true
    
    // Number of cards with cat images the user has seen.
    private var viewCount: Int = 0 {
        didSet {
            saveViewCount()
        }
    }
    
    private var onboardCompleted = false {
        didSet {
            defaults.setValue(onboardCompleted, forKey: K.UserDefaultsKeys.onboardCompleted)
        }
    }
    
    private var currentCard: Card? {
        return cardArray[pointer]
    }
    
    private var previousCard: Card? {
        return cardArray[pointer - 1]
    }
    
    private var nextCard: Card? {
        return cardArray[pointer + 1]
    }
    
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        pan.delegate = self
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        return pan
    }()
    
    private lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = {
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
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        tap.delegate = self
        
        return tap
    }()
    
    private lazy var adBannerView: GADBannerView = {
        // Set up the banner view with default size which is adjusted later according to the device's screen width.
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = K.Banner.adUnitID
        adBannerView.rootViewController = self
        adBannerView.delegate = self
        
        return adBannerView
    }()
    
    //MARK: - View Overriding Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Save the reference of this view's built-in navigation bar.
        navBar = self.navigationController?.navigationBar
        dbManager.delegate = self
        APIManager.shared.delegate = self
        
        // Load viewCount value from database if there's any.
        let savedViewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        viewCount = (savedViewCount != 0) ? savedViewCount : 0
        
        // Notify this VC that if the app enters the background, save the cached view count value to the db.
        NotificationCenter.default.addObserver(self, selector: #selector(saveViewCount), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Retrieve the user status from db.
        onboardCompleted = defaults.bool(forKey: K.UserDefaultsKeys.onboardCompleted)
        if !onboardCompleted {
            hideUIButtons()
        }
        
        // Create local image folder in file system and/or load data from it.
        dbManager.createFolders()
        dbManager.getSavedImageFileURLs()
        
        addBackgroundLayer()
        addShadeOverlay()
        
        sendAPIRequest(numberOfRequests: K.Data.numberOfPrefetchedData)
        
        // For UI Testing
        setUpUIReference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshButtonState()
        setBarStyle()
        backgroundLayer.frame = view.bounds
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { _ in
            self.backgroundLayer.frame = self.view.bounds
            if self.adReceived {
                // Request another banner ad if the orientation of the screen is changing
                self.updateBannerSpaceHeight(bannerView: self.adBannerView)
                self.requestBannerAd()
            }
        }
    }
    
    /// Auto hidden the home indicator.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Remove notif. observer to avoid sending notification to invalid obj.
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    //MARK: - Data Request & Handling
    
    /// Send data request to API Manager.
    /// - Parameter numberOfRequests: Number of request sent to API Manager.
    private func sendAPIRequest(numberOfRequests: Int) {
        let validatedRequestNumber = numberOfRequests > 0 ? numberOfRequests : 1
        for _ in 0..<validatedRequestNumber {
            APIManager.shared.fetchData()
        }
    }
    
    /// Once any new data is fetched via API by the network manager, the fetched data is passed to any delegate which conforms to its protocol: APIManagerDelegate.
    ///
    /// This method creates a new Card instance with the newly fetched data, assigned dataIndex and card's type based on the status on whether the onboard session is completed
    /// which is then appended to the cache card array.
    /// If there is none or only one card in the view, add one new card to it with the second card below the current card if there is any.
    /// - Parameters:
    ///   - data: Data fetched via API by network manager.
    ///   - dataIndex: An integer number which increments every time a new data is fetched and passed to its delegate.
    func dataDidFetch(data: CatData, dataIndex: Int) {
        DispatchQueue.main.async {
            let cardType: CardType = !self.onboardCompleted && dataIndex < self.onboardData.count ? .onboard : .regular
            let newCard = Card(data: data, index: dataIndex, type: cardType)
            self.cardArray[dataIndex] = newCard
            
            // Add the card to the view if it's the last card in the card array
            if newCard.index == self.pointer {
                self.addCardToView(newCard, atBottom: false)
                
                // Introduce the card by animating the change of the card size
                newCard.setSize(status: .intro)
                UIView.animate(withDuration: 0.3) {
                    newCard.transform = .identity
                } completion: { _ in
                    self.addGestureRecognizers(to: newCard)
                    self.refreshButtonState()
                    
                    // Update the number of cards viewed by the user
                    if self.onboardCompleted {
                        self.viewCount += 1
                    }
                }
            }
            
            // Add the card to the view if it's the next card
            if newCard.index == self.pointer + 1 {
                // Introduce the card by animating the change of the card size
                self.addCardToView(newCard, atBottom: true)
                newCard.setSize(status: .intro)
                UIView.animate(withDuration: 0.3) {
                    newCard.setSize(status: .standby)
                }
            }
        }
    }
    
    //MARK: - Card Introduction & Constraint
    
    /// Add a Card instance to the card view at assigned position.
    /// - Parameters:
    ///   - card: The card to be added to the view.
    ///   - atBottom: A boolean on whether the card would be added at the top or the bottom of the card view.
    private func addCardToView(_ card: Card, atBottom: Bool) {
        cardView.addSubview(card)
        addCardConstraint(card)
        card.optimizeContentMode()
        
        if atBottom {
            cardView.sendSubviewToBack(card)
            card.setSize(status: .standby)
        }
        
        if !onboardCompleted && card.index == onboardData.count {
            // Show UI buttons when the last onboarding card is showned to user
            showUIButtons()
        }
    }
    
    /// Activate the constraints which defines the position on where the card would be placed relative to the card view's position.
    /// - Parameter card: The card to which the constraint will be applied.
    private func addCardConstraint(_ card: Card) {
        let centerXAnchor = card.centerXAnchor.constraint(equalTo: cardView.centerXAnchor)
        let centerYAnchor = card.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        let heightAnchor = card.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.90)
        let widthAnchor = card.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.90)
        
        // Save constraints to the card's property for manipulation in the future
        card.centerXConstraint = centerXAnchor
        card.centerYConstraint = centerYAnchor
        card.heightConstraint = heightAnchor
        card.widthConstraint = widthAnchor
        
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.centerXConstraint, card.centerYConstraint, card.heightConstraint, card.widthConstraint
        ])
    }
    
    //MARK: - Background Layer & Shade Creation
    
    /// Set up the background color of the main view which is realized by a gradient layer consisting two colors.
    /// The light / dark theme of the background is set based on the device's interface style.
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
    
    /// Insert a gradient–color layer to the view as the background of the main view.
    private func addBackgroundLayer() {
        backgroundLayer = CAGradientLayer()
        backgroundLayer.frame = view.bounds
        setBackgroundColor()
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    /// Insert a black view below the card view with 0 opacity which is used to create shading effect when the card is being zoomed–in.
    private func addShadeOverlay() {
        zoomOverlay = UIView(frame: view.bounds)
        zoomOverlay.backgroundColor = .black
        zoomOverlay.alpha = 0
        view.insertSubview(zoomOverlay, belowSubview: cardView)
    }
    
    //MARK: - UI Buttons Visibility Control
    
    /// Disable and hide all button items in nav-bar and toolbar.
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
    
    /// Un–hidden all UI buttons.
    private func showUIButtons() {
        navBar.tintColor = K.Color.tintColor
        toolbar.alpha = 1
    }
    
    //MARK: - Ad Banner Methods
    
    /// Request ad for the ad banner.
    private func loadBannerAd() {
        DispatchQueue.main.async {
            self.adBannerView.load(GADRequest())
        }
    }
    
    /*
     Google recommends waiting for the completion callback prior to loading ads,
     so that if the user grants the App Tracking Transparency permission,
     the Google Mobile Ads SDK can use the IDFA in ad requests.
     */
    @available(iOS 14, *)
    private func requestIDFA() {
        ATTrackingManager.requestTrackingAuthorization { (status) in
            // Tracking authorization completed. Start loading ads here.
            self.loadBannerAd()
        }
    }
    
    /*
     If iOS version is 14 or above, request IDFA access permission from the user before requesting an Ad through AdMob API.
     Otherwise, request an ad immediately.
     */
    private func requestBannerAd() {
        if #available(iOS 14, *) {
            requestIDFA()
        } else {
            loadBannerAd()
        }
    }
    
    /// Add and place the ad banner at the center of the reserved ad space.
    private func addBannerToBannerSpace(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerSpace.addSubview(bannerView)
        
        // Define center position only. Width and height is defined later.
        NSLayoutConstraint.activate([
            bannerView.centerYAnchor.constraint(equalTo: bannerSpace.centerYAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerSpace.centerXAnchor)
        ])
    }
    
    /// Adapt the banner space's height according to the adaptive banner size with animation.
    /// This method should be called before presenting the banner ad onto the view.
    /// - Parameter bannerView: The banner view from which the banner space's height is adjusted.
    private func updateBannerSpaceHeight(bannerView: GADBannerView) {
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
        
        /*
         With adaptive banner, height of banner is based on the width of the banner itself
         Get Adaptive GADAdSize and set the ad view.
         Here the current interface orientation is used. If the ad is being preloaded
         for a future orientation change or different orientation, the function for the
         relevant orientation should be used.
         */
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        // Set the height of the reserved ad space the same as the adaptive banner's height
        bannerSpaceHeight.constant = bannerView.frame.height
        
        UIView.animate(withDuration: 0.5) {
            self.updateLayout() // Animate the update of bannerSpace's height
        }
    }
    
    //MARK: - Support Methods
    
    /// Save the value of card view count to user defaults
    @objc func saveViewCount() {
        defaults.setValue(viewCount, forKey: K.UserDefaultsKeys.viewCount)
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
    
    /// What happens when the undo button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned else { return }
        
        // Make sure data is available for the undo card
        guard previousCard != nil else { return }
        
        hapticManager.prepareImpactGenerator(style: .medium)
        maxPointerReached = pointer > maxPointerReached ? pointer : maxPointerReached
        undoButton.isEnabled = false
        hapticManager.impactHaptic?.impactOccurred()
        
        // Remove the next card from the superview.
        nextCard?.removeFromSuperview()
        
        addCardToView(previousCard!, atBottom: false)
        previousCard!.centerXConstraint.constant = 0
        previousCard!.centerYConstraint.constant = 0
        
        UIView.animate(withDuration: 0.5) {
            self.currentCard?.setSize(status: .standby)
            self.updateLayout()
            self.previousCard!.transform = .identity
        } completion: { _ in
            self.addGestureRecognizers(to: self.previousCard!)
            self.pointer -= 1
            DispatchQueue.main.async {
                self.refreshButtonState()
            }
            self.hapticManager.releaseImpactGenerator()
        }
    }
    
    /// What happens when the save button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned else { return }
        
        if let data = currentCard?.data {
            hapticManager.prepareImpactGenerator(style: .soft)
            hapticManager.prepareNotificationGenerator()
            
            // Save data if it's absent in database, otherwise delete it.
            let isSaved = dbManager.isDataSaved(data: data)
            
            switch isSaved {
            case false:
                dbManager.saveData(data) { success in
                    if success {
                        // Data is saved successfully
                        DispatchQueue.main.async {
                            self.showConfirmIcon()
                        }
                        hapticManager.notificationHaptic?.notificationOccurred(.success)
                    } else {
                        // Data is not saved successfully
                        hapticManager.notificationHaptic?.notificationOccurred(.error)
                    }
                }
            case true:
                dbManager.deleteData(id: data.id)
                hapticManager.impactHaptic?.impactOccurred()
            }
            
            refreshButtonState()
            hapticManager.releaseImpactGenerator()
            hapticManager.releaseNotificationGenerator()
        }
    }
    
    /// What happens when the save button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned, currentCard != nil else { return }
        let dataToShare = currentCard!.data
        
        // Get URL of the data for activity VC's image preview.
        guard let imageURL = dbManager.getImageTempURL(catData: dataToShare) else { return }
        
        hapticManager.prepareImpactGenerator(style: .soft)

        let activityVC = UIActivityViewController(activityItems: [imageURL], applicationActivities: nil)
        
        // Set up Popover Presentation Controller's barButtonItem for iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.barButtonItem = sender
        }
        
        self.present(activityVC, animated: true)
        
        hapticManager.impactHaptic?.impactOccurred()
        
        // Delete the cache image file after the activityVC is dismissed.
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            self.dbManager.removeFile(fromDirectory: .cachesDirectory, inFolder: K.Image.FolderName.cacheImage, fileName: dataToShare.id)
            
            self.hapticManager.releaseImpactGenerator()
        }
    }
    
    /// Update the availability of the toolbar buttons.
    private func refreshButtonState() {
        guard onboardCompleted && !cardArray.isEmpty else { return }
        
        if currentCard != nil {
            saveButton.isEnabled = true
            shareButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
            shareButton.isEnabled = false
        }
        
        undoButton.isEnabled = (pointer > 0 && previousCard != nil) ? true : false
        
        // Toggle the status of save button
        if let data = currentCard?.data {
            let isDataSaved = dbManager.isDataSaved(data: data)
            saveButton.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    /// Show feedback image to the user onced the card's image is saved successfully to the device.
    private func showConfirmIcon() {
        guard let card = currentCard else { return }
        let confirmView = ConfirmationView(parentView: card, confirmImage: K.Image.savedFeedbackImage)
        confirmView.startAnimation(withDelay: nil, duration: 0.4)
    }
    
    //MARK: - Gesture Recognizers
    
    /// Which part of the card the user's finger is placed onto.
    private enum Side {
        case upper, lower
    }
    
    private var firstFingerLocation: Side!
    
    var startingCenterX: CGFloat = 0
    var startingCenterY: CGFloat = 0
    var startingTransform: CGAffineTransform = .identity
    
    /// What happens when user drags the card with 1 finger.
    /// - Parameter sender: A discrete gesture recognizer that interprets panning gestures.
    @objc private func panHandler(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        
        let halfViewWidth = view.frame.width / 2
        
        // Save which side of the card the finger is placed
        let fingerPosition = sender.location(in: sender.view)
        let side: Side = fingerPosition.y < card.frame.midY ? .upper : .lower
        firstFingerLocation = (firstFingerLocation == nil) ? side : firstFingerLocation
        
        let translation = sender.translation(in: view)
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisOffset = card.centerXConstraint.constant
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let rotationDegree = (rotationAtMax / 5) * (xAxisOffset / halfViewWidth)
        
        // Card's rotation direction is based on the finger position on the card
        let cardRotationRadian = (firstFingerLocation == .upper) ? rotationDegree : -rotationDegree
        let velocity = sender.velocity(in: self.view) // points per second
        
        // Card's offset of x and y position
        let offset = CGPoint(x: card.centerXConstraint.constant, y: card.centerYConstraint.constant)
        
        // Distance of card's center to its origin point
        let panDistance = hypot(offset.x, offset.y)
        
        switch sender.state {
        case .began:
            startingCenterX = card.centerXConstraint.constant
            startingCenterY = card.centerYConstraint.constant
            startingTransform = card.transform
            
            cardIsBeingPanned = true
        case .changed:
            // Card move to where the user's finger is
            card.centerXConstraint.constant = startingCenterX + translation.x
            card.centerYConstraint.constant = startingCenterY + translation.y
            updateLayout()
            
            // Card's rotation increase when it approaches the side edge of the screen
            card.transform = startingTransform.concatenating(CGAffineTransform(rotationAngle: cardRotationRadian))
            
            // Set next card's transform based on current card's travel distance
            let distance = (panDistance <= halfViewWidth) ? (panDistance / halfViewWidth) : 1
            let defaultScale = K.Card.SizeScale.standby
            
            nextCard?.transform = CGAffineTransform(
                scaleX: defaultScale + (distance * (1 - defaultScale)),
                y: defaultScale + (distance * (1 - defaultScale))
            )
            
        // When user's finger left the screen.
        case .ended, .cancelled, .failed:
            firstFingerLocation = nil // Reset first finger location
            
            let minTravelDistance = view.frame.height // minimum travel distance of the card
            let minDragDistance = halfViewWidth // minimum dragging distance of the card
            let vector = CGPoint(x: velocity.x / 2, y: velocity.y / 2)
            let vectorDistance = hypot(vector.x, vector.y)
            
            let distanceDelta = minTravelDistance / panDistance
            let minimumDelta = CGPoint(x: offset.x * distanceDelta,
                                       y: offset.y * distanceDelta)
            
            if vectorDistance >= minTravelDistance {
                pointer += 1
                /*
                 Card dismissing threshold A:
                 The projected travel distance is greater than or equals minimum distance.
                 */
                dismissCard(card, deltaX: vector.x, deltaY: vector.y)
            }
            else if vectorDistance < minTravelDistance && panDistance >= minDragDistance {
                pointer += 1
                /*
                 Card dismissing thrshold B:
                 The projected travel distance is less than the minimum travel distance
                 but the distance of card being dragged is greater than distance threshold.
                 */
                dismissCard(card, deltaX: minimumDelta.x, deltaY: minimumDelta.y)
            }
            
            // Reset card's position and rotation.
            else {
                // Bouncing effect
                let bounceVector = CGPoint(x: -(offset.x) / 8, y: -(offset.y) / 8)
                card.centerXConstraint.constant = startingCenterX + bounceVector.x
                card.centerYConstraint.constant = startingCenterY + bounceVector.y
                
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    self.updateLayout()
                    card.transform = self.startingTransform
                    
                    // Reset the next card's transform
                    self.nextCard?.setSize(status: .standby)
                } completion: { _ in
                    card.centerXConstraint.constant = self.startingCenterX
                    card.centerYConstraint.constant = self.startingCenterY
                    
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn) {
                        self.updateLayout()
                    } completion: { _ in
                        self.cardIsBeingPanned = false
                    }
                }
            }
        default:
            return
        }
    }
    
    /// What happens when user uses two finger to pan the card.
    /// - Parameter sender: A discrete gesture recognizer that interprets panning gestures.
    @objc private func twoFingerPanHandler(sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        switch sender.state {
        case .began:
            startingCenterX = card.centerXConstraint.constant
            startingCenterY = card.centerYConstraint.constant
        case .changed:
            // Get the touch position
            let translation = sender.translation(in: card)
            
            // Card move to where the user's finger position is
            let zoomRatio = card.frame.width / card.bounds.width
            card.centerXConstraint.constant = startingCenterX + translation.x * zoomRatio
            card.centerYConstraint.constant = startingCenterY + translation.y * zoomRatio
            updateLayout()
            
        case .ended, .cancelled, .failed:
            // Move card back to original position
            card.centerXConstraint.constant = startingCenterX
            card.centerYConstraint.constant = startingCenterY
            UIView.animate(withDuration: 0.35, animations: {
                self.updateLayout()
            })
        default:
            return
        }
    }
    
    /// What happens when user pinches the card with 2 fingers.
    /// - Parameter sender: A discrete gesture recognizer that interprets pinching gestures involving two touches.
    @objc private func zoomHandler(sender: UIPinchGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        switch sender.state {
        case .began:
            startingTransform = card.transform
            
            // Hide navBar button
            if self.onboardCompleted {
                self.collectionButton.tintColor = .clear
            }
            
            // Hide card's trivia overlay
            card.hideTriviaOverlay()
            
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
            
            // Limit the scale at which a card can be zoom in/out
            let newWidth = sender.scale * card.frame.width
            let minWidth = card.bounds.width
            let maxWidth = minWidth * K.ImageView.maximumScaleFactor
            if newWidth > minWidth && newWidth < maxWidth {
                card.transform = startingTransform.concatenating(transform)
            }
            sender.scale = 1
            
            // Increase opacity of the overlay view as the card is enlarged
            let originalWidth = card.bounds.width
            let currentWidth = card.frame.width
            let maxOpacity: CGFloat = 0.6 // max opacity of the overlay view
            let cardWidthDelta = (currentWidth / originalWidth) - 1 // Percentage change of width
            let deltaToMaxOpacity: CGFloat = 0.2 // number of width delta to get maximum opacity
            
            zoomOverlay.alpha = maxOpacity * min((cardWidthDelta / deltaToMaxOpacity), 1.0)
            
        case .ended, .cancelled, .failed:
            // Reset card's size
            UIView.animate(withDuration: 0.35, animations: {
                card.transform = self.startingTransform
                self.zoomOverlay.alpha = 0
            }) { _ in
                if self.onboardCompleted {
                    self.collectionButton.tintColor = K.Color.tintColor
                }
            }
            
            // Re-show trivia overlay if showOverlay is true
            if showOverlay == true {
                card.showTriviaOverlay()
            }
        default:
            return
        }
        
    }
    
    /// What happens when user taps on the card.
    /// - Parameter sender: A discrete gesture recognizer that interprets single or multiple taps.
    @objc private func tapHandler(sender: UITapGestureRecognizer) {
        guard let card = sender.view as? Card else { return }
        if sender.state == .ended {
            switch card.cardType {
            case .regular:
                for card in cardArray.values {
                    card.toggleOverlay()
                }
            case .onboard:
                card.toggleOverlay()
            }
        }
    }
    
    /// Attach all gesturn recognizers to the designated card.
    /// - Parameter card: The card to which the gesture recognizers are attached.
    private func addGestureRecognizers(to card: Card?) {
        card?.addGestureRecognizer(panGestureRecognizer)
        card?.addGestureRecognizer(pinchGestureRecognizer)
        card?.addGestureRecognizer(twoFingerPanGestureRecognizer)
        card?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - Animation Methods
    
    /// Dismiss the card and reset the current card's size if there's any.
    /// - Parameters:
    ///   - card: The card to be dismissed.
    ///   - deltaX: X–axis delta applied to the card.
    ///   - deltaY: Y–axis delta applied to the card.
    private func dismissCard(_ card: Card, deltaX: CGFloat, deltaY: CGFloat) {
        card.centerXConstraint.constant += deltaX
        card.centerYConstraint.constant += deltaY
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.updateLayout()
            self.currentCard?.transform = .identity
        } completion: { _ in
            card.removeFromSuperview()
            self.cardIsBeingPanned = false
            
            // Attach gesture recognizers to the current card if there's any.
            self.addGestureRecognizers(to: self.currentCard)
            
            // Add the next card to the view if it's not nil.
            if self.nextCard != nil {
                self.addCardToView(self.nextCard!, atBottom: true)
            }
            
            // Fetch new data if the next card has not being displayed before.
            if self.pointer > self.maxPointerReached {
                self.sendAPIRequest(numberOfRequests: 1)
            }
            
            // Toggle the status of onboard completion
            if !self.onboardCompleted && self.pointer >= self.onboardData.count {
                self.onboardCompleted = true
                self.collectionButton.isEnabled = true
            }
            
            // Update the number of cards viewed by the user if onboard session is completed
            // and the current card has not been seen by the user before.
            if self.onboardCompleted && self.pointer > self.maxPointerReached {
                self.viewCount += 1
            }
            
            // Refresh the status of the toolbar's buttons.
            DispatchQueue.main.async {
                self.refreshButtonState()
            }
            
            // Clear the old card's cache data.
            self.clearOldCardCacheData()
            
            // Request banner ad if onboard session is completed, no ad is received yet,
            // and the number of cards seen by the user passes the threshold.
            if self.onboardCompleted && !self.adReceived && self.viewCount > K.Banner.adLoadingThreshold {
                self.requestBannerAd()
            }
        }
    }
    
    /// Lay out this view's subviews immediately, if layout updates are pending.
    private func updateLayout() {
        self.view.layoutIfNeeded()
    }
    
    /// Clear the card's cache data if its index position is beyond the bound of the undo–able range.
    private func clearOldCardCacheData() {
        let maxUndoNumber = K.Data.numberOfUndoCard
        let oldCardIndex = pointer - (maxUndoNumber + 1)
        if cardArray[oldCardIndex] != nil {
            cardArray[oldCardIndex] = nil
        }
        
    }
    
    //MARK: - Error Handling Section
    
    /// An error occured in the data fetching process.
    func APIErrorDidOccur(error: APIError) {
        // Present alert view to the user if any error occurs in the data fetching process.
        
        // Make sure no existing alert controller being presented already.
        guard self.presentedViewController == nil else { return }
        
        hapticManager.prepareNotificationGenerator()
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: Z.AlertMessage.APIError.alertTitle,
                message: Z.AlertMessage.APIError.alertMessage,
                preferredStyle: .alert)
            
            // An button which send network request to the network manager
            let retryAction = UIAlertAction(title: Z.AlertMessage.APIError.actionTitle, style: .default) { _ in
                // Request enough number of new data to satisfy the ideal cache data number.
                let requestNumber = K.Data.numberOfPrefetchedData - self.cardArray.count
                self.sendAPIRequest(numberOfRequests: requestNumber)
            }
            
            alert.addAction(retryAction)
            self.present(alert, animated: true, completion: nil)
            self.hapticManager.notificationHaptic?.notificationOccurred(.error)
            self.hapticManager.releaseNotificationGenerator()
        }
    }
    
    //MARK: - Testing
    
    private func setUpUIReference() {
        shareButton.accessibilityIdentifier = "shareButton"
        undoButton.accessibilityIdentifier = "undoButton"
        saveButton.accessibilityIdentifier = "saveButton"
        collectionButton.accessibilityIdentifier = "collectionButton"
    }
    
}

extension HomeVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow multiple gesture recognizers to be recognized simultaneously.
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Recognize pinch gesture only after the failure of single–finger pan gesture
        if gestureRecognizer == pinchGestureRecognizer && otherGestureRecognizer == panGestureRecognizer {
            return true
        }
        
        // Recognize two–finger pan gesture only after the failure of single–finger pan gesture
        if gestureRecognizer == twoFingerPanGestureRecognizer && otherGestureRecognizer == panGestureRecognizer {
            return true
        }
        
        // Recognize tap gesture only after the failure of single–finger pan gesture
        if gestureRecognizer == tapGestureRecognizer && otherGestureRecognizer == panGestureRecognizer {
            return true
        }
        
        return false
    }
}

extension HomeVC: DatabaseManagerDelegate {
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

extension HomeVC: GADBannerViewDelegate {
    /// An ad request successfully receive an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        if !adReceived {
            addBannerToBannerSpace(adBannerView)
            updateBannerSpaceHeight(bannerView: bannerView)
            
            adReceived = true
        }
        
        // Animate the appearence of the banner view
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
