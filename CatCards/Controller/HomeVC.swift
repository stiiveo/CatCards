//
//  HomeVC.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

final class HomeVC: UIViewController, APIManagerDelegate, HomeVCDelegate {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    // Superview to which all cards being added.
    @IBOutlet weak var cardView: UIView!
    
    // MARK: - Local Properties
    
    static let shared = HomeVC()
    private let defaults = UserDefaults.standard
    private let dbManager = DataManager.shared
    private let cacheManager = CacheManager.shared
    private let apiManager = APIManager.shared
    // Cache of all Card objects used to display to the user.
    internal var cardArray = [Int: Card]()
    // Array of string data used as the content of the onboard info.
    private let onboardData = K.OnboardOverlay.content
    private var navBar: UINavigationBar!
    private var backgroundLayer: CAGradientLayer!
    // A shading layer displayed behind the current card when the current card is zoomed–in by the user.
    internal var shadingLayer: UIView!
    // The pointer to which card being added to the top layer of cardView.
    internal var pointer: Int = 0 {
        didSet {
            if !onboardCompleted && pointer >= K.OnboardOverlay.content.count {
                onboardCompleted = true
            }
        }
    }
    // Maximum number of cards with different data shown to the user.
    internal var maxPointerReached: Int = 0
    internal var cardIsBeingPanned = false
    
    // Status on whether to show card info on all cards.
    static var showOverlay = true
    // Number of cards with cat images the user has seen.
    internal var viewCount: Int = 0
    // Status on if the onboard sessions were completed by the user.
    internal var onboardCompleted = false
    internal var currentCard: Card? { return cardArray[pointer] }
    private var previousCard: Card? { return cardArray[pointer - 1] }
    internal var nextCard: Card? { return cardArray[pointer + 1] }
    private var gesturesHandler: GesturesHandler!
    
    // MARK: - Overriding Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar = self.navigationController?.navigationBar
        gesturesHandler = GesturesHandler(delegate: self, superview: cardView)
        addBackgroundLayer()
        addShadeOverlay()
        dbManager.delegate = self
        apiManager.delegate = self
        loadStoredParameters()
        loadCachedData()
        requestNewDataIfNeeded()
        
        disableToolbarButtons()
        if !onboardCompleted {
            hideAndDisableUIButtons()
        }
        
        // Notify this VC that if the app enters the background, save the cached view count value to the db.
        NotificationCenter.default.addObserver(self, selector: #selector(takeActionsBeforeTermination), name: UIApplication.willTerminateNotification, object: nil)
        
        // UI testing references
        setUpUIReference()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshButtonState()
        setUpBarStyle()
        backgroundLayer.frame = view.bounds
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.backgroundLayer.frame = self.view.bounds
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Remove notif. observer to avoid sending notification to invalid obj.
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // MARK: - Cache Data Handling
    
    /// Cache the established data stored in the local variable cardArray to the standard system Cache directory.
    private func cacheData() {
        /*
         Since the downloaded data is stored in a dictionary,
         you need to sort the collection by its keys.
         Firstly, create a temporary array with sorted keys of the dictionary,
         then retrieve the data by the sorted keys and store it in a temporary collection.
         */
        let sortedCardArrayKeys = cardArray.keys.sorted()
        let sortedData = sortedCardArrayKeys.map { cardArray[$0]!.data }
        do {
            try cacheManager?.cacheData(sortedData)
        } catch CacheError.failedToCommitChangesToPersistentContainer {
            debugPrint("Failed to commit objects changes to Cache entity")
        } catch CacheError.failedToConvertImageToJpegData(let image) {
            debugPrint("Failed to convert image: \(image) to jpeg data.")
        } catch CacheError.failedToWriteImageFile(let url) {
            debugPrint("Failed to write image file to url: \(url)")
        } catch {
            debugPrint("Unknown error occured in the data caching operation: \(error)")
        }
    }
    
    private func loadCachedData() {
        guard let cachedData = cacheManager?.fetchCachedData() else { return }
        guard !cachedData.isEmpty else {
            pointer = 0
            debugPrint("No cached data saved.")
            return
        }
        
        // Create cards using cached data indexed starting from 0.
        for i in 0...cachedData.count - 1 {
            let card = Card(data: cachedData[i], index: i, type: .regular)
            cardArray[i] = card
        }
        // API manager's dataIndex starts from the index after the last index of the cached data.
        apiManager.dataIndex = cachedData.count

        /*
         Make sure the pointed card exist before adding it to the view, otherwise
         reset the pointer to 0 in case the number of cache data is insufficient.
         */
        if cardArray[pointer] != nil {
            addCacheCardToView()
        } else {
            pointer = 0
            addCacheCardToView()
        }
    }
    
    private func addCacheCardToView() {
        let pointedCard = cardArray[pointer]!
        addCardToView(pointedCard, atBottom: false)
        introduceCard(card: pointedCard, animated: false)
        
        if let nextCard = cardArray[pointer + 1] {
            addCardToView(nextCard, atBottom: true)
        }
    }
    
    /// Request new data to make the number of prefetched data meets the pre–set target.
    private func requestNewDataIfNeeded() {
        let numberOfNonUndoCard = cardArray.count - pointer
        let numberOfPrefetchData = K.Data.numberOfPrefetchedData
        if numberOfNonUndoCard < numberOfPrefetchData {
            let numberOfNewDataShort = numberOfPrefetchData - numberOfNonUndoCard
            sendAPIRequest(numberOfRequests: numberOfNewDataShort)
        }
    }
    
    /// Clear the card's cache data if its index position is beyond the bound of the undo–able range.
    internal func clearCacheData() {
        let maxUndoNumber = K.Data.numberOfUndoCard
        let oldCardIndex = pointer - (maxUndoNumber + 1)
        if let oldCard = cardArray[oldCardIndex] {
            do {
                // Clear the data in cardArray regardless if the cache clearing operation succeeded or not.
                defer {
                    cardArray[oldCardIndex] = nil
                }
                try cacheManager?.clearCache(dataId: oldCard.data.id)
            } catch CacheError.fileNotFound(let fileName) {
                debugPrint("Cache file '\(fileName)' cannot be removed because it's absent.")
            } catch {
                debugPrint("Unknown error occured when trying to remove cache data: \(error)")
            }
        }
        
    }
    
    // MARK: - Data Request & Handling
    
    /// Send data request to API Manager.
    /// - Parameter numberOfRequests: Number of request sent to API Manager.
    internal func sendAPIRequest(numberOfRequests: Int) {
        let validatedRequestNumber = numberOfRequests > 0 ? numberOfRequests : 1
        for _ in 0..<validatedRequestNumber {
            apiManager.fetchData()
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
                self.introduceCard(card: newCard, animated: true)
                
                // Update the number of cards viewed by the user
                if self.onboardCompleted {
                    self.viewCount += 1
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
    
    // MARK: - Card Introduction & Constraint
    
    /// Add a Card instance to the card view at assigned position.
    /// - Parameters:
    ///   - card: The card to be added to the view.
    ///   - atBottom: A boolean on whether the card would be added at the top or the bottom of the card view.
    internal func addCardToView(_ card: Card, atBottom: Bool) {
        cardView.addSubview(card)
        addCardConstraint(card)
        card.optimizeContentMode()
        
        // Add gesture recognizers if there's none.
        if card.gestureRecognizers == nil {
            gesturesHandler.addGestureRecognizers(to: card)
        }
        
        if atBottom {
            cardView.sendSubviewToBack(card)
            card.setSize(status: .standby)
        }
        
        // Show UI buttons when the last onboard card is shown to user
        if !onboardCompleted && card.index == onboardData.count {
            showUIButtons()
        }
    }
    
    private func introduceCard(card: Card, animated: Bool) {
        switch animated {
        case true:
            // Introduce the card by enlarging the card's size.
            card.setSize(status: .intro)
            UIView.animate(withDuration: 0.3) {
                card.transform = .identity
            } completion: { _ in
                self.refreshButtonState()
            }
        case false:
            card.setSize(status: .shown)
            self.refreshButtonState()
        }
    }
    
    /// - Parameter card: The card to which the constraint will be applied.
    private func addCardConstraint(_ card: Card) {
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            card.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.90),
            card.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.90)
        ])
    }
    
    // MARK: - Background Layer & Shade Creation
    
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
        shadingLayer = UIView(frame: view.bounds)
        view.insertSubview(shadingLayer, belowSubview: cardView)
        shadingLayer.backgroundColor = .black
        shadingLayer.alpha = 0
    }
    
    // MARK: - UI Buttons Status Control
    
    /// Disable and hide all button items in nav-bar and toolbar.
    private func hideAndDisableUIButtons() {
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
    
    // MARK: - Support Methods
    
    /// Hide navigation bar and toolbar's border line
    private func setUpBarStyle() {
        // Make background of navBar and toolbar transparent
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .bottom)
    }
    
    // MARK: - User Defaults Handling
    
    private func loadStoredParameters() {
        viewCount = defaults.integer(forKey: K.UserDefaultsKeys.viewCount)
        pointer = defaults.integer(forKey: K.UserDefaultsKeys.pointer)
        onboardCompleted = defaults.bool(forKey: K.UserDefaultsKeys.onboardCompleted)
    }
    
    @objc private func takeActionsBeforeTermination() {
        guard onboardCompleted else { return }
        saveOnboardStatus()
        savePointer()
        saveViewCount()
        cacheData()
    }
    
    private func saveOnboardStatus() {
        defaults.setValue(onboardCompleted, forKey: K.UserDefaultsKeys.onboardCompleted)
    }
    
    private func savePointer() {
        guard !cardArray.isEmpty else {
            debugPrint("Pointer cannot be saved to UserDefaults since cardArray: '\(cardArray)' is empty.")
            return
        }
        /*
         Since the index of cards created using the cached data will be reset
         and starting from 0, save the value of pointer which is the relative position of the cardArray,
         with the first card's index being 0.
         E.g. If the pointer was 105 and the first card's index in the array was 100,
         the first card's index will be reset to 0, thus the pointer will be 5, which
         is also the relative position to the first card's index.
         */
        let firstCardIndex = cardArray.keys.sorted().first!
        let pointerToSave = pointer - firstCardIndex
        defaults.setValue(pointerToSave, forKey: K.UserDefaultsKeys.pointer)
    }
    
    /// Save the value of card view count to user defaults
    private func saveViewCount() {
        defaults.setValue(viewCount, forKey: K.UserDefaultsKeys.viewCount)
    }
    
    // MARK: - Toolbar Button Method and State Control
    
    /// What happens when the undo button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned else { return }
        guard let undoCard = previousCard else { return }
        
        maxPointerReached = pointer > maxPointerReached ? pointer : maxPointerReached
        undoButton.isEnabled = false
        HapticManager.shared.vibrateForSelection()
        nextCard?.removeFromSuperview()
        addCardToView(undoCard, atBottom: false)
        
        /*
         Card created from cached data has no position offset at default.
         To create animation and improve user experience,
         add arbitrary position offset to the undoCard and reset its position with animation.
         */
        if undoCard.frame.size == .zero {
            // Place the card randomly to one of the corners of the view.
            var randomTranslation: CGFloat {
                let offset = cardView.frame.height * 2
                if Bool.random() {
                    return 1 * offset
                } else {
                    return -1 * offset
                }
            }
            let transform = CGAffineTransform(translationX: randomTranslation, y: randomTranslation)
            undoCard.transform = transform
        }
        
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [.curveEaseOut]) {
            self.currentCard?.setSize(status: .standby)
            undoCard.transform = .identity
        } completion: { _ in
            self.pointer -= 1
            DispatchQueue.main.async {
                self.refreshButtonState()
            }
        }
    }
    
    /// What happens when the save button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned else { return }
        
        if let data = currentCard?.data {
            // Save data if it's absent in database, otherwise delete it.
            let isSaved = dbManager.isDataSaved(data: data)
            
            switch isSaved {
            case false:
                // Current card's data is not saved yet.
                dbManager.saveData(data) { success in
                    guard success else {
                        // Data is not saved successfully
                        debugPrint("Current image cannot be saved. Image ID: \(currentCard!.data.id)")
                        HapticManager.shared.vibrate(for: .error)
                        return
                    }
                    // Data is saved successfully
                    DispatchQueue.main.async {
                        self.showConfirmIcon()
                    }
                    HapticManager.shared.vibrate(for: .success)
                }
            case true:
                // Current card's data is already saved.
                dbManager.deleteData(id: data.id)
                HapticManager.shared.vibrate(for: .success)
            }
            refreshButtonState()
        }
    }
    
    /// What happens when the save button is pressed.
    /// - Parameter sender: A specialized button for placement on a toolbar or tab bar.
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard !cardIsBeingPanned, currentCard != nil else { return }
        
        // Write the current card's image data to cache images folder named by its id value.
        let data = currentCard!.data
        let cacheManager = CacheManager()
        let fileName = data.id + K.File.fileExtension
        
        do {
            try cacheManager?.cacheImage(data.image, withFileName: fileName)
        } catch CacheError.failedToWriteImageFile(let fileUrl) {
            debugPrint("Failed to cache file \(fileName) to path: \(fileUrl.path)")
            return
        } catch {
            debugPrint("Unknown error occurred when caching image data with ID \(data.id)")
        }
        // Get the url of the cached image file.
        guard let imageFileUrl = cacheManager?.urlOfImageFile(fileName: fileName) else {
            debugPrint("Failed to get the url of the cached image file \(fileName)")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [imageFileUrl], applicationActivities: nil)
        
        // Set up Popover Presentation Controller's barButtonItem for iPad.
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.barButtonItem = sender
        }
        self.present(activityVC, animated: true)
        HapticManager.shared.vibrateForSelection()
        
        // Remove the cache image file after the activityVC is dismissed.
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            self.dbManager.removeFile(fromDirectory: .cachesDirectory, inFolder: K.File.FolderName.cacheImage, fileName: data.id)
        }
    }
    
    private func disableToolbarButtons() {
        shareButton.isEnabled = false
        undoButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    /// Update the availability of the toolbar buttons.
    internal func refreshButtonState() {
        guard onboardCompleted else { return }
        
        collectionButton.isEnabled = true
        if currentCard != nil {
            saveButton.isEnabled = true
            shareButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
            shareButton.isEnabled = false
        }
        undoButton.isEnabled = previousCard != nil ? true : false
        
        // Toggle the status of save button.
        if let data = currentCard?.data {
            let isDataSaved = dbManager.isDataSaved(data: data)
            saveButton.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
        }
    }
    
    /// Show feedback image to the user onced the card's image is saved successfully to the device.
    private func showConfirmIcon() {
        guard let card = currentCard else { return }
        let feedbackView = FeedbackView(parentView: card, image: K.Image.feedbackImage)
        feedbackView.startAnimation(withDelay: 0, duration: 0.4)
    }
    
    // MARK: - Error Handling Section
    
    func APIErrorDidOccur(error: APIError) {
        // Present alert view to the user if any error occurs in the data fetching process.
        DispatchQueue.main.async { [weak self] in
            // Make sure no existing alert controller being presented already.
            guard self?.presentedViewController == nil else { return }
            
            var alertTitle: String
            var alertMessage: String
            switch error {
            case .network:
                alertTitle = Z.AlertMessage.NetworkError.alertTitle
                alertMessage = Z.AlertMessage.NetworkError.alertMessage
            case .server:
                alertTitle = Z.AlertMessage.APIError.alertTitle
                alertMessage = Z.AlertMessage.APIError.alertMessage
            }
        
            let alert = UIAlertController(
                title: alertTitle,
                message: alertMessage,
                preferredStyle: .alert)
            
            // An button which send network request to the network manager
            let retryAction = UIAlertAction(title: Z.AlertMessage.APIError.actionTitle, style: .default) { _ in
                // Request enough number of new data to satisfy the ideal cache data number.
                let requestNumber = K.Data.numberOfPrefetchedData - (self?.cardArray.count ?? 0)
                self?.sendAPIRequest(numberOfRequests: requestNumber)
            }
            
            alert.addAction(retryAction)
            self?.present(alert, animated: true, completion: nil)
            HapticManager.shared.vibrate(for: .error)
        }
    }
    
    // MARK: - UI Testing
    
    private func setUpUIReference() {
        toolbar.accessibilityIdentifier = "toolbar"
        shareButton.accessibilityIdentifier = "shareButton"
        undoButton.accessibilityIdentifier = "undoButton"
        saveButton.accessibilityIdentifier = "saveButton"
        collectionButton.accessibilityIdentifier = "collectionButton"
    }
    
}
