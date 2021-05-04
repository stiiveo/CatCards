//
//  Card.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/11/2.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

enum CardType {
    case onboard, regular
}

enum GestureRecognizerTag: String {
    case panGR = "panGR"
    case twoFingerPanGR = "twoFingerPanGR"
    case pinchGR = "pinchGR"
    case tapGR = "tapGR"
}

final class Card: UIView {

    var data: CatData
    var index: Int
    var cardType: CardType
    private let imageView = UIImageView()
    private let bgImageView = UIImageView()
    private var onboardOverlay: OnboardOverlay?
    private var triviaOverlay: TriviaOverlay?
    
    // This class's attached gesture recognizers
    var panGR: UIPanGestureRecognizer? {
        if let gestureRecognizers = self.gestureRecognizers {
            for gr in gestureRecognizers {
                if gr.name == GestureRecognizerTag.panGR.rawValue {
                    return gr as? UIPanGestureRecognizer
                }
            }
        }
        return nil
    }
    var twoFingerPanGR: UIPanGestureRecognizer? {
        if let gestureRecognizers = self.gestureRecognizers {
            for gr in gestureRecognizers {
                if gr.name == GestureRecognizerTag.twoFingerPanGR.rawValue {
                    return gr as? UIPanGestureRecognizer
                }
            }
        }
        return nil
    }
    var pinchGR: UIPinchGestureRecognizer? {
        if let gestureRecognizers = self.gestureRecognizers {
            for gr in gestureRecognizers {
                if gr.name == GestureRecognizerTag.pinchGR.rawValue {
                    return gr as? UIPinchGestureRecognizer
                }
            }
        }
        return nil
    }
    var tapGR: UITapGestureRecognizer? {
        if let gestureRecognizers = self.gestureRecognizers {
            for gr in gestureRecognizers {
                if gr.name == GestureRecognizerTag.tapGR.rawValue {
                    return gr as? UITapGestureRecognizer
                }
            }
        }
        return nil
    }
    
    //MARK: - Initialization
    
    init(data: CatData, index: Int, type cardType: CardType) {
        self.data = data
        self.index = index
        self.cardType = cardType
        super.init(frame: .zero)
        cardDidInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func cardDidInit() {
        setUpBackground()
        setUpImageView()
        addOverlay()
    }
    
    deinit {
        print("Card with index \(index) is been deinitialized.")
    }
    
    //MARK: - Style & Shadow
    
    // Customize the card's style
    override func layoutSubviews() {
        self.layer.cornerRadius = K.Card.Style.cornerRadius
        
        // Shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 3.0
        
        /// Decrease the performance impact of drawing the shadow by specifying the shape and render it as a bitmap before compositing.
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: K.Card.Style.cornerRadius).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    //MARK: - Size Control
    
    enum Status {
        case intro, standby, shown
    }
    
    func setSize(status: Status) {
        switch status {
        case .intro:
            self.transform = CGAffineTransform(scaleX: K.Card.SizeScale.intro, y: K.Card.SizeScale.intro)
        case .standby:
            self.transform = CGAffineTransform(scaleX: K.Card.SizeScale.standby, y: K.Card.SizeScale.standby)
        case .shown:
            self.transform = .identity
        }
    }
    
    //MARK: - Image & Background
    
    /// Insert duplicated imageView with blur effect on top of it as a filter below the primary imageView as the card's background.
    private func setUpBackground() {
        self.addSubview(bgImageView)
        bgImageView.frame = self.bounds
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        bgImageView.layer.cornerRadius = K.Card.Style.cornerRadius
        bgImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgImageView.image = data.image
        
        // Place blur effect onto it.
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bgImageView.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        bgImageView.addSubview(blurEffectView)
    }
    
    private func setUpImageView() {
        self.addSubview(imageView)
        imageView.frame = self.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.clipsToBounds = true
        imageView.image = data.image
        
        // Style
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = K.Card.Style.cornerRadius
    }
    
    //MARK: - Overlay
    
    private func addOverlay() {
        switch cardType {
        case .regular:
            addTriviaOverlay()
        case .onboard:
            addOnboardOverlay()
        }
    }
    
    private func addOnboardOverlay() {
        // Make sure the index is within the bound of onboard data array.
        let onboardData = K.OnboardOverlay.content
        guard index >= 0 && index < onboardData.count else {
            debugPrint("Index(\(index)) of onboard data is unavailable for onboard card")
            return
        }
        
        if index == 1 {
            // Use built–in image for the second onboard card.
            data = CatData(id: K.OnboardOverlay.zoomImageFileID, image: K.OnboardOverlay.zoomImage)
            imageView.image = data.image
            bgImageView.image = data.image
        }
        
        // Create an onboard overlay instance and add it to Card.
        onboardOverlay = OnboardOverlay(cardIndex: index)
        imageView.addSubview(onboardOverlay!)
        onboardOverlay!.frame = self.bounds
        onboardOverlay!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func addTriviaOverlay() {
        triviaOverlay = TriviaOverlay()
        imageView.addSubview(triviaOverlay!)
        triviaOverlay!.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            triviaOverlay!.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            triviaOverlay!.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            triviaOverlay!.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            triviaOverlay!.topAnchor.constraint(greaterThanOrEqualTo: imageView.topAnchor)
        ])
        
        // Show / Hidden the overlay depends on the value of `showOverlay` in HomeVC.
        triviaOverlay?.alpha = HomeVC.showOverlay ? 1 : 0
    }
    
    func toggleOverlay() {
        UIView.animate(withDuration: 0.3) {
            switch self.cardType {
            case .regular:
                self.triviaOverlay?.alpha = HomeVC.showOverlay ? 1 : 0
            case .onboard:
                self.onboardOverlay?.alpha = self.onboardOverlay?.alpha == 1 ? 0 : 1
            }
            
        }
    }
    
    func hideTriviaOverlay() {
        UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.triviaOverlay?.alpha = 0
        }.startAnimation()
    }
    
    func showTriviaOverlay() {
        UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.triviaOverlay?.alpha = 1
        }.startAnimation()
    }
    
    //MARK: - Content Mode Optimization
    
    /// Calculate the difference between the ratio of the superview and the image.
    /// If the ratio difference equals or is less than the pre–set threshold, set the imageView's content mode to `scaleAspectFill`.
    func optimizeContentMode() {
        guard let image = imageView.image else { return }
        if let referenceFrame = superview {
            let frame = referenceFrame.frame
            let frameRatio = frame.width / frame.height
            let imageRatio = image.size.width / image.size.height
            let ratioDifference = abs(imageRatio - frameRatio)
            let ratioThreshold = K.ImageView.dynamicScaleThreshold

            imageView.contentMode = (ratioDifference <= ratioThreshold) ? .scaleAspectFill : .scaleAspectFit
        }
    }
    
}

