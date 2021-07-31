//
//  TriviaOverlay.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/9.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

final class TriviaOverlay: UIView {
    
    private var blurEffectView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundView()
        addTriviaLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Background & Label Set Up
    
    private func addBackgroundView() {
        // Only applies blur effect view on top of this view if the user hadn't disable transparency effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear
            
            // Blur effect setting
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView?.frame = bounds
            blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.addSubview(blurEffectView)
        } else {
            self.backgroundColor = K.Color.onboardBackground
        }
    }
    
    private func addTriviaLabel() {
        let label = UILabel()
        addView(label,
                to: blurEffectView?.contentView ?? self,
                withOffset: AutoLayoutOffset(leading: 15, trailing: 15, top: 10, bottom: 15))
        
        label.text = OverlayContentPicker.shared.randomContent(contentTypes: [.trivia, .quote])
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
    }
}
