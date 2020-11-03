//
//  CardView.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/11/2.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CardView: UIView {

    let imageView = UIImageView()
    let indicator = UIActivityIndicatorView()
    var data: CatData? {
        didSet {
            guard data != nil else {
                imageView.image = nil
                indicator.startAnimating()
                return
            }
            // value of data is not nil
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
                self.set(image: self.data!.image)
            }
            
        }
    }
    
    var isShown: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        addImageViewConstraint()
        addIndicator()
        imageView.isUserInteractionEnabled = true
        indicator.startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(image: UIImage) {
        imageView.image = image
        setContentMode(image: image)
    }
    
    func setContentMode(image: UIImage) {
        let imageAspectRatio = image.size.width / image.size.height
        let imageViewAspectRatio = imageView.bounds.width / imageView.bounds.height
        // Determine the content mode by comparing the aspect ratio of the image and image view
        let aspectRatioDiff = abs(imageAspectRatio - imageViewAspectRatio)
        imageView.contentMode = (aspectRatioDiff >= K.ImageView.dynamicScaleThreshold) ? .scaleAspectFit : .scaleAspectFill
    }
    
    func addImageViewConstraint() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // Style
        imageView.layer.cornerRadius = K.CardView.Style.cornerRadius
        imageView.clipsToBounds = true
    }
    
    func addIndicator() {
        self.addSubview(indicator)
        // constraint
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        // style
        indicator.style = .large
        indicator.hidesWhenStopped = true
    }
    
}
