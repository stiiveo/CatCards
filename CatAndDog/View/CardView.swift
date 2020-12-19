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
            loadImage()
        }
    }
    var labelView = LabelView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addImageView()
        addIndicator()
        self.clipsToBounds = true // Make sure all subclasses' bounds are within this view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    private func addImageView() {
        self.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // Style
        imageView.isUserInteractionEnabled = true
        imageView.alpha = 0 // Default status
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
    
    private func loadImage() {
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
    
    class LabelView: UIView {
        
        let label = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            // Set labelView's style
            self.backgroundColor = .clear
            self.clipsToBounds = true
            
            // Create background view
            let backgroundView = UIView(frame: self.bounds)
            self.addSubview(backgroundView)
            backgroundView.backgroundColor = .secondarySystemBackground
            backgroundView.alpha = 0.9
            
            // Create and put label onto the background view
            // By adding uiLabel as a subview to a uiview and attaching constraints to it
            // it creates same effect as having margins inside the uiLabel view itself
            backgroundView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30),
                label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30),
                label.topAnchor.constraint(equalTo: self.topAnchor, constant: 30),
                label.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -30)
            ])
            
            // Label Text Style
            label.textColor = .label
            label.font = .preferredFont(forTextStyle: .title1)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 0
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private func addLabelView() {
        // Create an LabelView instance and add it to CardView
        self.labelView = LabelView(frame: self.bounds)
        self.addSubview(self.labelView)
    }
    
    func setAsTutorialCard(withHintText text: String) {
        DispatchQueue.main.async {
            self.addLabelView()
            self.labelView.label.text = text
        }
    }
    
}
