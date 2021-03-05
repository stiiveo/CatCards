//
//  Card.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/11/2.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class Card: UIView {

    var centerXConstraint: NSLayoutConstraint!
    var centerYConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!
    var data: CatData?
    private let imageView = UIImageView()
    private let backgroundImageView = UIImageView()
    var overlayView: OverlayView?
    var index: Int = 0
    
    //MARK: - Overriding Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addImageView()
        addBluredImageBackground()
        addOverlay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Customize the card's style
    override func layoutSubviews() {
        self.layer.cornerRadius = K.Card.Style.cornerRadius
        
        // Shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 5
        
        /// Decrease the performance impact of drawing the shadow by specifying the shape and render it as a bitmap before compositing.
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: K.Card.Style.cornerRadius).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    //MARK: - ImageView & Background
    
    private func addImageView() {
        self.addSubview(imageView)
        imageView.frame = self.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Style
        imageView.isUserInteractionEnabled = true
        imageView.alpha = 0 // Default status
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = K.Card.Style.cornerRadius
    }
    
    /// Insert duplicated imageView with blur effect on top of it as a filter below the primary imageView as the card's background.
    private func addBluredImageBackground() {
        self.insertSubview(backgroundImageView, belowSubview: imageView)
        backgroundImageView.frame = imageView.frame
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = K.Card.Style.cornerRadius
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add blur effect onto it
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundImageView.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundImageView.addSubview(blurEffectView)
    }
    
    //MARK: - Overlay Methods
    
    private func addOverlay() {
        // Create an onboard overlay instance and add it to Card
        overlayView = OverlayView(frame: imageView.bounds)
        imageView.addSubview(overlayView!)
        overlayView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func setAsTutorialCard(cardIndex index: Int) {
        guard index < K.Onboard.data.count else {
            debugPrint("Index(\(index)) of onboard data is unavailable for onboard card")
            return
        }
        
        if index == 1 {
            data = CatData(id: "zoomImage", image: K.Onboard.zoomImage)
        }
        
        DispatchQueue.main.async {
            self.overlayView?.addTableView(toCard: index)
            self.overlayView?.alpha = 1
        }
    }
    
    //MARK: - Image Updating
    
    func updateImage() {
        // Data is valid
        if data != nil {
            DispatchQueue.main.async {
                // Set imageView's image
                self.setImage(self.data!.image)
                
                UIView.animate(withDuration: 0.2) {
                    self.imageView.alpha = 1
                }
            }
        }
        // Data is NOT valid
        else {
            overlayView?.removeFromSuperview() // Remove onboardOverlay if there's any
            imageView.image = nil
            backgroundImageView.image = nil
            
            // Animate indicator and hide imageView
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    self.imageView.alpha = 0
                }
            }
        }
        
    }
    
    private func setImage(_ image: UIImage) {
        imageView.image = image
        backgroundImageView.image = imageView.image
        optimizeContentMode()
    }
    
    /// If the aspect ratio of the image and the imageView is close enough,
    /// set the imageView's content mode to 'scale aspect fill' mode to remove the margins around the image and
    /// improve the viewing experience
    private func optimizeContentMode() {
        guard let image = imageView.image else { return }
        
        let imageRatio = image.size.width / image.size.height
        let imageViewRatio = imageView.bounds.width / imageView.bounds.height
        
        // Calculate the difference of the aspect ratio between the image and image view
        let ratioDifference = abs(imageRatio - imageViewRatio)
        let ratioThreshold = K.ImageView.dynamicScaleThreshold
        
        imageView.contentMode = (ratioDifference > ratioThreshold) ? .scaleAspectFit : .scaleAspectFill
    }
    
    //MARK: - Memory Management
    
    func clearCache() {
        data = nil
        imageView.image = nil
        backgroundImageView.image = nil
    }
    
}

