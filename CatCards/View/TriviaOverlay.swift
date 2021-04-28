//
//  TriviaOverlay.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/9.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

class TriviaOverlay: UIView {
    
    private var blurEffectView = UIVisualEffectView()
    
    //MARK: - Init
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: .zero)
        addBackgroundView()
        addTriviaLabel()
    }
    
    //MARK: - Background & Label
    
    private func addBackgroundView() {
        // Only applies blur effect view on top of this view if the user hadn't disable transparancy effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear
            
            // Blur effect setting
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            // Always fill the view
            blurEffectView.frame = self.frame
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.addSubview(blurEffectView)
        } else {
            self.backgroundColor = K.Color.onboardBackground
        }
    }
    
    private func addTriviaLabel() {
        let label = UILabel()
        blurEffectView.contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor, constant: -15),
            label.topAnchor.constraint(equalTo: blurEffectView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor, constant: -15)
        ])
        
        // Label text and style
        label.text = OverlayContentPicker.shared.randomContent(contentTypes: [.trivia, .quote])
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
    }
}
