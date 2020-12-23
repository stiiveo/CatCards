//
//  HintView.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/12/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class HintView: UIView {
    
    let label = UILabel()
    
    // Contents of the onboard cards
    private let data = [
        OnboardData(title: Z.InstructionText.swipeGesture, content: nil, prompt: Z.InstructionText.prompt),
        OnboardData(title: Z.InstructionText.buttonInstruction,
                    content: [
                        K.Onboard.ButtonImage.shareButton: Z.InstructionText.shareButton,
                        K.Onboard.ButtonImage.undoButton: Z.InstructionText.undoButton,
                        K.Onboard.ButtonImage.saveButton: Z.InstructionText.saveButton,
                    ],
                    prompt: Z.InstructionText.prompt),
        OnboardData(title: Z.InstructionText.bless, content: nil, prompt: Z.InstructionText.prompt)
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addBackgroundView()
        addLabel(to: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Add background view and blur effect to the label view
    private func addBackgroundView() {
        // Only applies blur effect view on top of this view if the user hadn't disable transparancy effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear
            
            // Blur effect setting
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            // Always fill the view
            blurEffectView.frame = frame
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.addSubview(blurEffectView)
        } else {
            self.backgroundColor = UIColor(named: "onboardBackground")
        }
    }
    
    /// Create and put label onto the background view.
    /// By adding uiLabel as a subview to a uiview and attaching constraints to it.
    /// It creates same effect as having margins inside the uiLabel view itself
    private func addLabel(to view: UIView) {
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            label.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -30)
        ])
        
        setLabelStyle()
    }
    
    private func setLabelStyle() {
        // Label Text Style
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
    }
}

