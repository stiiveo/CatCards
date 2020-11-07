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
        
        // Create local image folder in file system or load data from it if it already exists
        databaseManager.createDirectory()
        databaseManager.loadImagesFromLocalSystem()
        
        // Disable favorite and share button before data is downloaded
        favoriteBtn.isEnabled = false
        shareBtn.isEnabled = false
        
        // Undo button is disabled until one card is dismissed by user
        undoBtn.isEnabled = false
        
        setDownsampleSize() // Prepare ImageProcess's operation parameter
        
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
    
    //MARK: - Save Device Screen Info
    private func setDownsampleSize() {
        // Device with wider screen (iPhone Plus and Max series) has one more cell per row than other devices
        let screenWidth = UIScreen.main.bounds.width
        var cellNumberPerRow: CGFloat {
            if screenWidth >= 414 {
                return 4.0
            } else {
                return 3.0
            }
        }
        let interCellSpacing: CGFloat = 1.5
        let cellWidth = floor((screenWidth - (interCellSpacing * (cellNumberPerRow - 1))) / cellNumberPerRow)
        
        // Floor the calculated width to remove any decimal number
        let cellSize = CGSize(width: cellWidth, height: cellWidth)
        databaseManager.imageProcess.cellSize = cellSize
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
        
        // Place undoed card onto the current card
        view.addSubview(undoCard)
        addCardViewConstraint(card: undoCard)
        
        UIView.animate(withDuration: 0.5) {
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
    
    private func rotateCard(_ card: CardView) {
        nextCard = (card == firstCard) ? .firstCard : .secondCard
        self.currentCard = (nextCard == .firstCard) ? .second : .first
        
        card.data = nil
        let currentCard = (self.currentCard == .first) ? firstCard : secondCard
        attachGestureRecognizers(to: currentCard)
        
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
    
    enum Side {
        case upper
        case lower
    }
    
    var firstFingerLocation: Side?
    
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
            
            if currentData != nil && speed > speedThreshold && travelDistance > distanceThreshold {
                animateNextCardTransform()
                undoCard.data = currentData!
                animateCard(card, withVelocity: velocity)
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
            print("Error handling card panning detection.")
        }
    }
    
    private func animateCard(_ card: CardView, withVelocity velocity: CGPoint) {
        let destination = CGPoint(x: cardViewAnchor.x + velocity.x / 2, y: cardViewAnchor.y + velocity.y / 2)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            card.center = destination
            
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
            self.undoBtn.isEnabled = true
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
                print("Error handling image panning")
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
                print("Error handling image zooming")
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
