//
//  MainViewController.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/21.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

enum Card {
    case firstCard
    case secondCard
}

enum CurrentView {
    case first
    case second
    case undo
}

enum Side {
    case left
    case right
}

class MainViewController: UIViewController, NetworkManagerDelegate {
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    @IBOutlet weak var undoBtn: UIBarButtonItem!
    
    private var networkManager = NetworkManager()
    private let databaseManager = DatabaseManager()
    private let firstCard = CardView()
    private let secondCard = CardView()
    private let undoCard = CardView()
    private var cardViewAnchor = CGPoint()
    private var imageViewAnchor = CGPoint()
    private var dataIndex: Int = 0
    private var currentCard: CurrentView = .first
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
    private var nextCard: Card = .secondCard
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkManager.delegate = self
        toolBar.heightAnchor.constraint(equalToConstant: K.ToolBar.height).isActive = true // define toolBar's height
        fetchNewData(initialRequest: true) // initiate data downloading
        
        // Add cardView, ImageView and implement neccesary constraints
        view.addSubview(firstCard)
        view.insertSubview(secondCard, belowSubview: firstCard)
        
        addCardViewConstraint(card: firstCard)
        addCardViewConstraint(card: secondCard)
        secondCard.transform = CGAffineTransform(scaleX: K.CardView.Size.transform, y: K.CardView.Size.transform)
        
        // Create local image folder in file system or load data from it
        databaseManager.createDirectory()
        databaseManager.loadImages()
        
        // Disable favorite and share button before data is downloaded
        favoriteBtn.isEnabled = false
        shareBtn.isEnabled = false
        
        // Undo button is disabled until one card is dismissed by user
        undoBtn.isEnabled = false
        
        // TEST AREA
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Save the center position of the created card view
        cardViewAnchor = firstCard.center
        imageViewAnchor = firstCard.imageView.center
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Un-hidden nav bar's hairline
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
    
    //MARK: - Toolbar Button Method and State Control
    
    private func refreshButtonState() {
        var isDataLoaded: Bool { return currentData != nil }
        favoriteBtn.isEnabled = isDataLoaded ? true : false
        shareBtn.isEnabled = isDataLoaded ? true : false
        if isDataLoaded {
            if let data = currentData {
                let isDataSaved = databaseManager.isDataSaved(data: data)
                favoriteBtn.image = isDataSaved ? K.ButtonImage.filledHeart : K.ButtonImage.heart
            }
        }
        
    }
    
    //MARK: - Undo Action
    
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
            print("Error: Undo button should have not been enabled")
        }
        
        // Insert undo card to main view
        view.addSubview(undoCard)
        addCardViewConstraint(card: undoCard)
        
        UIView.animate(withDuration: 0.5) {
            self.undoCard.center = self.cardViewAnchor
            self.undoCard.transform = .identity
            switch self.currentCard {
            case .first:
                self.firstCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            case .second:
                self.secondCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            case .undo:
                print("Error: Undo button should have not been enabled")
            }
        } completion: { (true) in
            if true {
                // Add gesture recognizer to undo card
                self.attachGestureRecognizers(to: self.undoCard)
                self.currentCard = .undo
                
                // Update favorite button image
                self.refreshButtonState()
            }
        }
        
    }
    
    //MARK: - Favorite Action
    
    @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
        if let data = currentData {
            // Save data if it's absent in database, otherwise delete it in database
            let isDataSaved = databaseManager.isDataSaved(data: data)
            switch isDataSaved {
            case false:
                databaseManager.saveData(data)
                self.favoriteBtn.image = K.ButtonImage.filledHeart
            case true:
                databaseManager.deleteData(id: data.id)
                self.favoriteBtn.image = K.ButtonImage.heart
            }
        }
    }
    
    //MARK: - Share Action
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        if let imageToShare = currentData?.image {
            let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
            present(activityController, animated: true)
        }
    }
    
    //MARK: - Constraints and Style Methods
    
    // Add constraints to cardView
    private func addCardViewConstraint(card: UIView) {
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: K.CardView.Constraint.leading),
            card.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: K.CardView.Constraint.trailing),
            card.topAnchor.constraint(equalTo: self.view.topAnchor, constant: K.CardView.Constraint.top),
            card.bottomAnchor.constraint(equalTo: self.toolBar.topAnchor, constant: K.CardView.Constraint.bottom)
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
                DispatchQueue.main.async {
                    
                    // Refresh toolbar buttons' state
                    self.refreshButtonState()
                    
                    // Add gesture recognizer to first card
                    self.attachGestureRecognizers(to: self.firstCard)
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
    
    private func resetCardTransform() {
        UIView.animate(withDuration: 0.1) {
            switch self.currentCard {
            case .first:
                self.secondCard.transform = .identity
            case .second:
                self.firstCard.transform = .identity
            case .undo:
                switch self.nextCard {
                case .firstCard:
                    self.firstCard.transform = .identity
                case .secondCard:
                    self.secondCard.transform = .identity
                }
            }
        }
    }
    
    private func animateCard(_ card: CardView, to side: Side, from releasePoint: CGPoint) {
        enum Zone {
            case upper
            case middle
            case lower
        }
        
        // Determine the zone of the release point
        var zone: Zone?
        let screenHeight = UIScreen.main.bounds.height
        let releasePointY = releasePoint.y
        
        if releasePointY < screenHeight / 3 {
            zone = .upper
        } else if (releasePointY >= screenHeight / 3) && (releasePointY < screenHeight * 2/3) {
            zone = .middle
        } else if releasePointY >= (screenHeight * 2/3) {
            zone = .lower
        }
        
        // Move the card to the edge of either side of the screen depending on where the card was released at
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            guard zone != nil else { return }
            let screenWidth = UIScreen.main.bounds.width
            var destination: CGPoint?
            switch side {
            case .left:
                switch zone! {
                case .upper:
                    destination = CGPoint(x: releasePoint.x - screenWidth, y: releasePoint.y - screenWidth)
                case .middle:
                    destination = CGPoint(x: releasePoint.x - screenWidth, y: releasePoint.y)
                case .lower:
                    destination = CGPoint(x: releasePoint.x - screenWidth, y: releasePoint.y + screenWidth)
                }
            case .right:
                switch zone! {
                case .upper:
                    destination = CGPoint(x: releasePoint.x + screenWidth, y: releasePoint.y - screenWidth)
                case .middle:
                    destination = CGPoint(x: releasePoint.x + screenWidth, y: releasePoint.y)
                case .lower:
                    destination = CGPoint(x: releasePoint.x + screenWidth, y: releasePoint.y + screenWidth)
                }
            }
            guard destination != nil else { return }
            card.center = destination!
            
        } completion: { (true) in
            if true {
                self.undoCard.center = card.center
                self.undoCard.transform = card.transform
                
                self.removeGestureRecognizers(from: card)
                card.removeFromSuperview()
                
                switch self.currentCard {
                case .first:
                    card.transform = CGAffineTransform.identity
                    self.rotateCard(self.firstCard)
                case .second:
                    card.transform = CGAffineTransform.identity
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
                // Re-enable undo button
                self.undoBtn.isEnabled = true
            }
        }
    }
    
    private func rotateCard(_ dismissedCard: CardView) {
        nextCard = (dismissedCard == firstCard) ? .firstCard : .secondCard
        let cardToShow = (dismissedCard == firstCard) ? secondCard : firstCard
        currentCard = (cardToShow == firstCard) ? .first : .second
        
        dismissedCard.data = nil
        // Attach gesture recognizer
        attachGestureRecognizers(to: cardToShow)
        
        // Put the dismissed card behind the current card
        self.view.insertSubview(dismissedCard, belowSubview: cardToShow)
        dismissedCard.center = cardViewAnchor
        addCardViewConstraint(card: dismissedCard)
        
        // Shrink the size of the newly added card view
        dismissedCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        updateCardView()
        fetchNewData(initialRequest: false)
    }
    
    //MARK: - Update Image of imageView
    
    // Prepare the next cardView to be shown
    private func updateCardView() {
        let dataSet = networkManager.serializedData
        let dataAllocation: Card = ((self.dataIndex + 1) % 2 == 1) ? .firstCard : .secondCard
        
        if let newData = dataSet[dataIndex + 1] { // New data is available
            switch dataAllocation {
            case .firstCard: // Data is for first card
                firstCard.data = newData
                dataIndex += 1
            case .secondCard: // Data is for second card
                secondCard.data = newData
                dataIndex += 1
            }
        }
        DispatchQueue.main.async {
            self.refreshButtonState()
        }
    }
    
    //MARK: - Card Panning Methods
    
    /// Handling the cardView's panning effect which is responded to user's input via finger dragging on the cardView itself.
    /// - Parameter sender: A concrete subclass of UIGestureRecognizer that looks for panning (dragging) gestures.
    @objc private func handleCardPan(_ sender: UIPanGestureRecognizer) {
        guard let card = sender.view as? CardView else { return }
        
        let halfViewWidth = view.frame.width / 2
        
        // Point of the finger in the view's coordinate system
        let fingerMovement = sender.translation(in: view)
        
        // Amount of x-axis offset the card moved from its original position
        let xAxisOffset = card.center.x - cardViewAnchor.x
        
        // 1.0 Radian = 180º
        let rotationAtMax: CGFloat = 1.0
        let cardRotationRadian = (rotationAtMax / 3) * (xAxisOffset / halfViewWidth)
        
        switch sender.state {
        case .changed:
            // Disable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = false
            }
            
            // Card move to where the user's finger is
            card.center = CGPoint(x: cardViewAnchor.x + fingerMovement.x, y: cardViewAnchor.y + fingerMovement.y)
            
            // Card's rotation increase when it approaches the side edge of the screen
            card.transform = CGAffineTransform(rotationAngle: cardRotationRadian)
            
            // Revert the card view behind to its original size as the current view is moved away from its original position
            var xOffset: CGFloat {
                if abs(xAxisOffset) <= halfViewWidth {
                    return abs(xAxisOffset) / halfViewWidth
                } else {
                    return 1
                }
            }
            
            // Change the size of the card behind
            let transform = K.CardView.Size.transform
            var cardToTransform = CardView()
            switch nextCard {
            case .firstCard:
                cardToTransform = firstCard
            case .secondCard:
                cardToTransform = secondCard
            }
            
            cardToTransform.transform = CGAffineTransform(
                scaleX: transform + (xOffset * (1 - transform)),
                y: transform + (xOffset * (1 - transform))
            )
            
        // When user's finger left the screen
        default:
            // Re-enable image's gesture recognizers
            for gestureRecognizer in card.imageView.gestureRecognizers! {
                gestureRecognizer.isEnabled = true
            }
            
            /*
             Card is dismissed when it's dragged to either side of the screen
             AND the current image view's data is not invalid
             */
            let releasePoint = CGPoint(x: card.frame.midX, y: card.frame.midY)
            if card.center.x < halfViewWidth / 2 && currentData != nil { // card was at the left side of the screen
                resetCardTransform()
                undoCard.data = currentData!
                animateCard(card, to: .left, from: releasePoint)
            }
            else if card.center.x > halfViewWidth * 3/2 && currentData != nil { // card was at the right side of the screen
                resetCardTransform()
                undoCard.data = currentData!
                animateCard(card, to: .right, from: releasePoint)
            }
            // Reset card's position and rotation state
            else {
                UIView.animate(withDuration: 0.2) {
                    card.center = self.cardViewAnchor
                    card.transform = CGAffineTransform.identity
                    
                    // Revert the size of the card view behind
                    switch self.currentCard {
                    case .first:
                        self.secondCard.transform = CGAffineTransform(
                            scaleX: K.CardView.Size.transform,
                            y: K.CardView.Size.transform
                        )
                    case .second:
                        self.firstCard.transform = CGAffineTransform(
                            scaleX: K.CardView.Size.transform,
                            y: K.CardView.Size.transform
                        )
                    case .undo:
                        switch self.nextCard {
                        case .firstCard:
                            self.firstCard.transform = CGAffineTransform(
                                scaleX: K.CardView.Size.transform,
                                y: K.CardView.Size.transform
                            )
                        case .secondCard:
                            self.secondCard.transform = CGAffineTransform(
                                scaleX: K.CardView.Size.transform,
                                y: K.CardView.Size.transform
                            )
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Image Zooming and Panning Methods
    
    @objc private func handleImagePan(sender: UIPanGestureRecognizer) {
        if let view = sender.view {
            switch sender.state {
            case .changed:
                // Get the touch position
                let translation = sender.translation(in: view)
                
                // Edit the center of the target by adding the gesture position
                let zoomRatio = view.frame.width / view.bounds.width
                view.center = CGPoint(
                    x: view.center.x + translation.x * zoomRatio,
                    y: view.center.y + translation.y * zoomRatio
                )
                sender.setTranslation(.zero, in: view)
                
            default:
                // Smoothly restore the transform to the original state
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
                    view.center = self.imageViewAnchor
                })
            }
        }
    }
    
    @objc private func handleImageZoom(sender: UIPinchGestureRecognizer) {
        if let view = sender.view {
            let cardBounds = view.bounds
            let cardFrame = view.frame
            switch sender.state {
            case .changed:
                // Coordinate of the pinch center where the view's center is (0, 0)
                let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                          y: sender.location(in: view).y - view.bounds.midY)
                let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                    .scaledBy(x: sender.scale, y: sender.scale)
                    .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
                
                // Limit the minimum scale the card can be zoomed out
                if cardFrame.width >= cardBounds.width {
                    view.transform = transform
                } else {
                    view.transform = CGAffineTransform.identity
                }
                
                sender.scale = 1
            default:
                // If the gesture has cancelled/terminated/failed or everything else that's not performing
                // Smoothly restore the transform to the "original"
                UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
                    view.transform = .identity
                })
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

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
