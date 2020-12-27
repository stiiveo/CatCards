//
//  CardView.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/11/2.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CardView: UIView {

    internal let imageView = UIImageView()
    private let indicator = UIActivityIndicatorView()
    internal var data: CatData? {
        didSet {
            reloadImageData()
        }
    }
    var hintView = HintView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setCardViewStyle()
        addImageView()
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
        // Data is not valid
        else {
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
        // To fill the empty place on the card
        // if the current imageView is in scale aspect fit mode,
        // add another imageView with the same image in .scaleAspectFill mode behind the current imageView
        // and put a blur effect onto it
        if imageView.contentMode == .scaleAspectFit {
            fillEmptySpaceOnCardView()
        }
    }
    
    func setAsTutorialCard(cardIndex index: Int) {
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
    
    private func fillEmptySpaceOnCardView() {
        // Add new imageView behind the current one
        let secondImageView = UIImageView()
        secondImageView.image = self.imageView.image
        self.insertSubview(secondImageView, belowSubview: imageView)
        secondImageView.frame = imageView.frame
        secondImageView.contentMode = .scaleAspectFill
        secondImageView.clipsToBounds = true
        secondImageView.layer.cornerRadius = K.CardView.Style.cornerRadius
        
        // Add blur effect onto it
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = secondImageView.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        secondImageView.addSubview(blurEffectView)
    }
    
}

