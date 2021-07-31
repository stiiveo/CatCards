//
//  OnboardOverlay.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/12/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

final class OnboardOverlay: UIView {
    
    private lazy var cardIndex: Int = 0
    
    // MARK: - Initialization
    
    init(cardIndex: Int) {
        super.init(frame: .zero)
        self.cardIndex = cardIndex
        addBlurredBackground()
        addContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Stack View
    
    private func addContent() {
        // Content
        let tableView = OverlayTableView(dataSource: self)
        let labelView = OverlayPromptLabel(cardIndex: self.cardIndex)
        let stackView = UIStackView(arrangedSubviews: [tableView, labelView])
        stackView.axis = .vertical
        stackView.distribution = .fill
        
        if self.cardIndex == 2 {
            // Insert tap gesture hint image to the stackView.
            let imageView = UIImageView(image: K.OnboardOverlay.tapGestureImage)
            imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            imageView.contentMode = .scaleAspectFit
            stackView.insertArrangedSubview(imageView, at: 1)
        }
        addView(stackView,
                to: self,
                withOffset: AutoLayoutOffset(leading: 10, trailing: 10, top: 15, bottom: 20))
    }
    
    // MARK: - Background
    
    /// Add background view and blur effect to the label view
    private func addBlurredBackground() {
        guard cardIndex != 1 else { return }
        
        // Only applies blur effect view on top of this view if the user hadn't disable transparancy effects
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.backgroundColor = .clear
            
            // Blur effect setting
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.frame
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.addSubview(blurEffectView)
        } else {
            self.backgroundColor = K.Color.onboardBackground
        }
    }
}

// MARK: - Content

/// The tableView which organizes all the onboard text and image content.
final class OverlayTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
    }
    
    convenience init(dataSource: UITableViewDataSource) {
        self.init()
        self.dataSource = dataSource
        tableViewDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableViewDidLoad() {
        self.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Configuration
        self.separatorStyle = .none
        self.backgroundColor = .clear
        self.isScrollEnabled = false
        self.allowsSelection = false
    }
}

/// The label placed at the bottom position of the card as a hint prompt.
final class OverlayPromptLabel: UILabel {
    
    private var cardIndex: Int!
    
    init(cardIndex: Int) {
        super.init(frame: .zero)
        self.cardIndex = cardIndex
        labelDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func labelDidLoad() {
        self.textColor = .label
        self.font = .preferredFont(forTextStyle: .caption1)
        self.adjustsFontForContentSizeCategory = true
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.5
        self.textAlignment = .center
        
        if cardIndex != K.OnboardOverlay.content.count - 1 {
            self.text = Z.Onboard.continuePrompt
        } else {
            self.text = Z.Onboard.finalPrompt
        }
    }
}

// MARK: - Data Source

extension OnboardOverlay: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let onboardContent = K.OnboardOverlay.content
        return onboardContent[cardIndex].content.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .clear
        
        // Label content
        let onboardContent = K.OnboardOverlay.content
        if indexPath.row == 0 {
            // Title
            cell.textLabel?.text = onboardContent[cardIndex].title
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        } else {
            // Body
            cell.textLabel?.text = onboardContent[cardIndex].content[indexPath.row - 1].text
            cell.imageView?.image = onboardContent[cardIndex].content[indexPath.row - 1].image
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        // Label style
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.5
        cell.textLabel?.textColor = .label
        
        return cell
    }
}
