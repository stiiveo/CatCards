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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundView()
        addTriviaLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Background & Label
    
    private func addBackgroundView() {
        // Only applies blur effect view on top of this view if the user hadn't disable transparancy effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear
            
            // Blur effect setting
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
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
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor, constant: -15),
            label.topAnchor.constraint(equalTo: blurEffectView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor, constant: -15)
        ])
        
        // Set content and style
        label.setContent()
        label.setStyle()
    }
}

//MARK: - Trivia Content

extension UILabel {
    func setContent() {
        self.text = Z.Trivia.trivia_0
    }
    
    func setStyle() {
        self.font = UIFont.systemFont(ofSize: 18)
        self.numberOfLines = 0
    }
}
