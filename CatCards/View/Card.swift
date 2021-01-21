//
//  Card.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/11/2.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class Card: UIView {

    var centerX: NSLayoutConstraint!
    var centerY: NSLayoutConstraint!
    var height: NSLayoutConstraint!
    var width: NSLayoutConstraint!
    let imageView = UIImageView()
    private let backgroundImageView = UIImageView()
    private let indicator = UIActivityIndicatorView()
    var data: CatData? {
        didSet {
            reloadImageData()
        }
    }
    var hintView = HintView()
    var isShown = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setCardViewStyle()
        addImageView()
        addBackgroundImageView()
        addIndicator()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setCardViewStyle() {
        // Card Style
        self.backgroundColor = K.CardView.Style.backgroundColor
        self.layer.cornerRadius = K.CardView.Style.cornerRadius
        
        // Card Shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
        self.layer.shadowRadius = 5
    }
    
    private func addImageView() {
        self.addSubview(imageView)
        imageView.frame = self.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Style
        imageView.isUserInteractionEnabled = true
        imageView.alpha = 0 // Default status
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = K.CardView.Style.cornerRadius
    }
    
    /// Add duplicated imageView with blur effect behind the primary one as the background
    /// and fill the empty space in the cardView.
    private func addBackgroundImageView() {
        self.insertSubview(backgroundImageView, belowSubview: imageView)
        backgroundImageView.frame = imageView.frame
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = K.CardView.Style.cornerRadius
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add blur effect onto it
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundImageView.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundImageView.addSubview(blurEffectView)
    }
    
    private func addIndicator() {
        self.addSubview(indicator)
        // constraint
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        // style
        indicator.style = .large
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
    }
    
    private func reloadImageData() {
        // Data is valid
        if data != nil {
            DispatchQueue.main.async {
                self.set(image: self.data!.image)
                
                UIView.animate(withDuration: 0.2) {
                    self.indicator.alpha = 0
                    self.imageView.alpha = 1
                } completion: { _ in
                    self.indicator.stopAnimating()
                }
                
            }
        }
        // Data is NOT valid
        else {
            hintView.removeFromSuperview() // Remove hintView if there's any
            imageView.image = nil
            backgroundImageView.image = nil
            
            // Animate indicator and hide imageView
            DispatchQueue.main.async {
                self.indicator.startAnimating()
                UIView.animate(withDuration: 0.2) {
                    self.imageView.alpha = 0
                    self.indicator.alpha = 1
                }
            }
        }
        
    }
    
    private func set(image: UIImage) {
        imageView.image = image
        backgroundImageView.image = self.imageView.image
        setContentMode(image: image)
    }
    
    private func setContentMode(image: UIImage) {
        let imageAspectRatio = image.size.width / image.size.height
        var imageViewAspectRatio = imageView.bounds.width / imageView.bounds.height
        // When the first undo card's image is set, the bounds of the imageView is yet to be defined (width = 0, height = 0),
        // Which makes the value of 'imageViewAspectRatio' to be 'Not a Number'.
        // If this happens, forcely set aspect ratio to 1 to prevent unwanted result.
        if imageViewAspectRatio.isNaN == true {
            imageViewAspectRatio = 1
        }
        // Determine the content mode by comparing the aspect ratio of the image and image view
        let aspectRatioDiff = abs(imageAspectRatio - imageViewAspectRatio)
        
        imageView.contentMode = (aspectRatioDiff >= K.ImageView.dynamicScaleThreshold) ? .scaleAspectFit : .scaleAspectFill
    }
    
    func setAsTutorialCard(cardIndex index: Int) {
        if index == 1 {
            data = CatData(id: "zoomImage", image: K.Onboard.zoomImage)
        }
        
        DispatchQueue.main.async {
            self.addHintView(toCard: index)
        }
    }
    
    private func addHintView(toCard index: Int) {
        // Create an HintView instance and add it to CardView
        hintView = HintView(frame: imageView.bounds)
        imageView.addSubview(hintView)
        hintView.addContentView(toCard: index)
    }
    
}

