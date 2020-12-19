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
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var adFixedSpace: UIView!
    @IBOutlet weak var adFixedSpaceHeight: NSLayoutConstraint!
    @IBOutlet weak var goToCollectionViewBtn: UIBarButtonItem!
    
    //MARK: - Global Properties
    
    private var navBar: UINavigationBar!
    private lazy var networkManager = NetworkManager()
    static let databaseManager = DatabaseManager()
    private let defaults = UserDefaults.standard
    private let firstCard = CardView()
    private let secondCard = CardView()
    private let undoCard = CardView()
    private lazy var cardViewAnchor = CGPoint()
    private lazy var imageViewAnchor = CGPoint()
    private var cardsAreCreated = false
    private var dataIndex: Int = 0
    private var currentCard: CurrentView = .first
    private var nextCard: Card = .secondCard
    private var cardHintDisplayed = false
    private var toolbarHintDisplayed = false
    private var navBarHintDisplayed = false
    
    private var viewCount: Int! { // Number of cards with cat images the user has seen
        didSet {
            if viewCount == 10 {
                defaults.setValue(true, forKey: K.UserDefaultsKeys.loadAdBanner)
            }
        }
    }
    
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
        fetchNewData(initialRequest: true) // initiate data downloading
        
        // Configure default status of toolbar's item buttons
        saveButton.isEnabled = false
        shareButton.isEnabled = false
        undoButton.isEnabled = false
        
        currentCard = .first
        
        // Create local image folder in file system or load data from it if it already exists
        MainViewController.databaseManager.createDirectory()
        MainViewController.databaseManager.getImageFileURLs()
        
        setDownsampleSize() // Prepare ImageProcess's operation parameter
        
        // Load value from defaults if there's any
        let savedViewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        self.viewCount = (savedViewCount != 0) ? savedViewCount : 0
        
        // Determine if the user is a new comer or old user
        let isOldUser = defaults.bool(forKey: K.UserDefaultsKeys.isOldUser)
        if isOldUser {
            cardHintDisplayed = true
            toolbarHintDisplayed = true
            navBarHintDisplayed = true
        } 
        
        // Notify this VC that when the app entered the background, execute selected method.
        NotificationCenter.default.addObserver(self, selector: #selector(saveViewCount), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh favorite button's image
        refreshButtonState()
        
        // Hide navigation bar's border line
        navBar.isTranslucent = false
        navBar.barTintColor = K.Color.backgroundColor
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        
        // Hide toolbar's hairline
        self.toolBar.clipsToBounds = true
        self.toolBar.barTintColor = K.Color.backgroundColor
        self.toolBar.isTranslucent = false
        
        addBannerToView(adBannerView)
        
        // * CardView can only be added to the view after the height of the ad banner is known.
        if !cardsAreCreated {
            addCardsToView()
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
        navBar.setBackgroundImage(nil, for: .default)
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
    private var topToToolbarTopConstraint: NSLayoutConstraint!
    private var topToToolbarBottomConstraint: NSLayoutConstraint!
    private var topToCardTopConstraint: NSLayoutConstraint!
    
    /// Disable and hide button items in nav-bar and toolbar
    private func disableAllButtons() {
        navBar.tintColor = K.Color.backgroundColor
        goToCollectionViewBtn.isEnabled = false
        
        toolBar.alpha = 0
        shareButton.isEnabled = false
        undoButton.isEnabled = false
        saveButton.isEnabled = false
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
        
        topToToolbarTopConstraint = hintView.topAnchor.constraint(equalTo: toolBar.topAnchor, constant: 10)
        NSLayoutConstraint.activate([
            topToToolbarTopConstraint,
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
            hintLabel.leadingAnchor.constraint(equalTo: hintView.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: hintView.trailingAnchor, constant: -20),
            hintLabel.bottomAnchor.constraint(equalTo: hintView.bottomAnchor, constant: -15)
        ])
        
        // Text label style
        hintLabel.text = Z.OnboardingLabel.cardGesture
        hintLabel.textColor = K.Color.backgroundColor
        hintLabel.font = .systemFont(ofSize: 20, weight: .medium)
        hintLabel.adjustsFontSizeToFitWidth = true
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .natural
        
        // Start the animation
        // Animate the appearence of the message block
        hintView.alpha = 0
        UIView.animate(withDuration: 0.8, delay: 0.2) {
            self.hintView.alpha = 1
        } completion: { _ in
            // Rotate the first card to hint the user how swiping gesture works
            // Rotate the first card to right
            UIView.animate(withDuration: 0.3, delay: 0.3) {
                self.firstCard.transform = CGAffineTransform(rotationAngle: 0.1)
                self.firstCard.center = CGPoint(x: anchorPoint.x + 20, y: anchorPoint.y)
            } completion: { _ in
                // Rotate the first card to left
                UIView.animate(withDuration: 0.3) {
                    self.firstCard.transform = CGAffineTransform(rotationAngle: -0.1)
                    self.firstCard.center = CGPoint(x: anchorPoint.x - 20, y: anchorPoint.y)
                } completion: { _ in
                    // Rotate the first card back to original position
                    UIView.animate(withDuration: 0.3) {
                        self.firstCard.transform = .identity
                        self.firstCard.center = anchorPoint
                    } completion: { _ in
                        self.cardHintDisplayed = true
                    }

                }
            }
        }
        
    }
    
    /// Show the user how each toolbar button works.
    private func displayToolbarTutorial() {
        guard !toolbarHintDisplayed else { return } // Make sure the tutorial was not displayed before.
        
        // Move the hintView to overlay on top of the bottom part of toolbar.
        topToToolbarBottomConstraint = hintView.topAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 10)
        
        // Hide the hintView and the first card under the second card
        UIView.animate(withDuration: 0.5) {
            self.hintView.alpha = 0
            self.firstCard.alpha = 0
        } completion: { _ in
            self.secondCard.gestureRecognizers?.first?.isEnabled = false // Disable second card's gesture recognizer
            
            // Set hintView's new top anchor constraint
            self.topToToolbarTopConstraint.isActive = false
            self.topToToolbarBottomConstraint.isActive = true
            
            // Set second hintView's tutorial message
            self.hintLabel.text = Z.OnboardingLabel.shareButton
            self.hintLabel.textAlignment = .center
            
            // Make second card transparant
            UIView.animate(withDuration: 0.8, delay: 0.2) {
                self.secondCard.alpha = 0.5
            } completion: { _ in
                // Show the toolbar
                UIView.animate(withDuration: 0.5, delay: 0.0) {
                    self.toolBar.alpha = 1
                } completion: { _ in
                    // Show the second hint view
                    UIView.animate(withDuration: 0.1, delay: 0.8) {
                        self.shareButton.isEnabled = true // Enable share button
                    } completion: { _ in
                        UIView.animate(withDuration: 0.5, delay: 0.5) {
                            self.hintView.alpha = 1
                        } completion: { _ in
                            // Hide hintView
                            UIView.animate(withDuration: 0.8, delay: 1.5) {
                                self.hintLabel.alpha = 0
                            } completion: { _ in
                                // Enable the undo button only and update the hintLabel
                                self.shareButton.isEnabled = false
                                self.undoButton.isEnabled = true
                                self.hintLabel.text = Z.OnboardingLabel.undoButton
                                UIView.animate(withDuration: 0.5) {
                                    self.hintLabel.alpha = 1
                                } completion: { _ in
                                    // Hide the hintView
                                    UIView.animate(withDuration: 0.8, delay: 1.5) {
                                        self.hintLabel.alpha = 0
                                    } completion: { _ in
                                        self.undoButton.isEnabled = false
                                        self.saveButton.isEnabled = true
                                        self.hintLabel.text = Z.OnboardingLabel.saveButton
                                        UIView.animate(withDuration: 0.5) {
                                            self.hintLabel.alpha = 1
                                        } completion: { _ in
                                            // Hide the hintView
                                            UIView.animate(withDuration: 0.8, delay: 1.5) {
                                                self.hintView.alpha = 0
                                            } completion: { _ in
                                                self.saveButton.isEnabled = false
                                                self.toolbarHintDisplayed = true // Toolbar tutorial completed
                                                self.displayNavBarButtonTutorial()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
        
    /// Tutorial of nav-bar button
    private func displayNavBarButtonTutorial() {
        // Move the hintView to overlay on top of the upper part of second card.
        topToCardTopConstraint = hintView.topAnchor.constraint(equalTo: secondCard.topAnchor)
        
        // Show hintView below the nav-bar
        self.hintLabel.text = Z.OnboardingLabel.browseButton
        topToToolbarBottomConstraint.isActive = false
        topToCardTopConstraint.isActive = true
        
        // Show go-to-collection-view nav-bar button
        UIView.animate(withDuration: 0.5, delay: 1.5) {
            self.goToCollectionViewBtn.isEnabled = true
            self.navBar.tintColor = K.Color.tintColor
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 0.3) {
                self.hintView.alpha = 1
            } completion: { _ in
                // Hide the hintView
                UIView.animate(withDuration: 0.8, delay: 2.0) {
                    self.hintView.alpha = 0
                } completion: { _ in
                    self.goToCollectionViewBtn.isEnabled = false
                    
                    // Move the hintView below the toolbar
                    self.topToCardTopConstraint.isActive = false
                    self.topToToolbarBottomConstraint.isActive = true
                    
                    self.hintLabel.text = Z.OnboardingLabel.blessLabel
                    
                    // Show the hintView
                    UIView.animate(withDuration: 0.5, delay: 0.5) {
                        self.hintView.alpha = 1
                    } completion: { _ in
                        // Hide the hintView
                        UIView.animate(withDuration: 0.8, delay: 0.8) {
                            self.hintView.alpha = 0
                        } completion: { _ in
                            self.navBarHintDisplayed = true
                            // Toggle the state of isOldUser in defaults to true
                            self.defaults.setValue(true, forKey: K.UserDefaultsKeys.isOldUser)
                            
                            // Enable card view
                            UIView.animate(withDuration: 0.5, delay: 0.2) {
                                self.secondCard.alpha = 1
                            } completion: { _ in
                                UIView.animate(withDuration: 0.1, delay: 0.8) {
                                    self.firstCard.alpha = 1
                                    // Enable second card's GR and all buttons
                                    self.secondCard.gestureRecognizers?.first?.isEnabled = true
                                    
                                    self.shareButton.isEnabled = true
                                    self.undoButton.isEnabled = true
                                    self.saveButton.isEnabled = true
                                    self.goToCollectionViewBtn.isEnabled = true
                                    
                                    // End of all tutorials
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Disable the nav-bar button until the tutorial is completed.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == K.SegueIdentifiers.mainToCollection {
            return navBarHintDisplayed
        } else {
            return true
        }
    }
    
    //MARK: - Advertisement Methods
    
    private func loadBannerAd() {
        // Create an ad request and load the adaptive banner ad.
        DispatchQueue.main.async {
            self.adBannerView.load(GADRequest())
        }
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
    
    /// Google recommend waiting for the completion callback prior to loading ads, so that if the user grants the App Tracking Transparency permission, the Google Mobile Ads SDK can use the IDFA in ad requests.
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
        guard viewCount != nil else { return }
        defaults.setValue(viewCount, forKey: K.UserDefaultsKeys.viewCount)
    }
    
    /// Determine if the user is the new user
    private func isOldUser() -> Bool {
        return defaults.bool(forKey: K.UserDefaultsKeys.isOldUser)
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
    
    //MARK: - Toolbar Button Method and State Control
    
    private func refreshButtonState() {
        guard toolbarHintDisplayed else { return } // Make sure the toolbar tutorial had been shown.
        
        // Toggle the availability of toolbar buttons
        let dataIsLoaded = currentData != nil
        saveButton.isEnabled = dataIsLoaded ? true : false
        shareButton.isEnabled = dataIsLoaded ? true : false
        
        let currentDataID = currentData?.id
        let firstDataID = networkManager.serializedData[1]?.id
        let isFirstCard = currentDataID == firstDataID
        undoButton.isEnabled = currentCard != .undo && !isFirstCard ? true : false
        
        // Toggle the status of favorite button
        if let data = currentData {
            let isDataSaved = MainViewController.databaseManager.isDataSaved(data: data)
            saveButton.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    // Undo Action
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        guard navBarHintDisplayed else { return }
        guard undoCard.data != nil else { return }
        
        undoButton.isEnabled = false
        
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
        guard navBarHintDisplayed else { return }
        
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
        guard navBarHintDisplayed else { return }
        
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
        secondCard.transform = CGAffineTransform(scaleX: K.CardView.Size.transform, y: K.CardView.Size.transform)
        
        cardsAreCreated = true
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
            if let firstData = dataSet[dataIndex] {
                firstCard.data = firstData
                dataIndex += 1
                viewCount += 1 // Increment the number of cat the user has seen
                
                DispatchQueue.main.async {
                    // Refresh toolbar buttons' state
                    self.refreshButtonState()
                    
                    // Add gesture recognizer to first card
                    self.attachGestureRecognizers(to: self.firstCard)
                    
                    // Load ad banner after the first card's data is loaded
                    if self.defaults.bool(forKey: K.UserDefaultsKeys.loadAdBanner) {
                        self.loadBannerAd()
                    }
                }
            }
        case 1:
            if let secondData = dataSet[dataIndex] {
                secondCard.data = secondData
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
        
        // Load ad banner if bool value in defaults is true and the user had viewed 10 cardViews with cat image
        // This method is put here to avoid the cardView dismissing issue where
        // the card dismissing destination might be disrupted if the constraints on view changed when
        // the dismissing animation is still executing at the same time.
        // If this issue is solved in the future, consider move this method
        // to a place which makes more sense.
        let loadAd = defaults.bool(forKey: K.UserDefaultsKeys.loadAdBanner)
        if loadAd && viewCount == 10 {
            if #available(iOS 14, *) {
                // This method is available in iOS 14 and later
                // User's permission is required to get device's identifier for advertising
                requestIDFA()
            } else {
                loadBannerAd()
            }
        }
    }
    
    //MARK: - Update Image of imageView
    
    /// Update card's content if new data is available.
    private func updateCardView() {
        let dataSet = networkManager.serializedData
        let dataAllocation: Card = ((self.dataIndex) % 2 == 1) ? .secondCard : .firstCard
        
        if let newData = dataSet[dataIndex] { // Make sure new data is available
            switch dataAllocation { // Decide which card the data is to be allocated
            case .firstCard:
                firstCard.data = newData
                dataIndex += 1
            case .secondCard:
                secondCard.data = newData
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
            firstFingerLocation = nil // Reset first finger location
            
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
                
                if !toolbarHintDisplayed {
                    self.displayToolbarTutorial() // Display toolbar tutorial
                }
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
        let alert = UIAlertController(title: Z.AlertMessage.DatabaseError.alertTitle, message: Z.AlertMessage.DatabaseError.alertMessage, preferredStyle: .alert)
        let acknowledgeAction = UIAlertAction(title: Z.AlertMessage.DatabaseError.actionTitle, style: .cancel)
        alert.addAction(acknowledgeAction)
        
        present(alert, animated: true, completion: nil)
    }
}
