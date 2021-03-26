//
//  OnboardOverlay.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/12/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class OnboardOverlay: UIView {
    
    var cardIndex: Int = 0
    private let tableViewContent = K.OnboardOverlay.data
    private lazy var blurEffectView = UIVisualEffectView()
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(cardIndex: Int) {
        self.init()
        self.cardIndex = cardIndex
        OverlayDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func OverlayDidLoad() {
        addBlurBackground()
        addContent()
    }
    
    //MARK: - Stack View
    
    private func addContent() {
        // Content
        let tableView = OverlayTableView(dataSource: self)
        let labelView = OverlayPromptLabel(cardIndex: self.cardIndex)
        let stackView = UIStackView(arrangedSubviews: [tableView, labelView])
        if self.cardIndex == 2 {
            let imageView = UIImageView(image: K.OnboardOverlay.tapGesture)
            imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            imageView.contentMode = .scaleAspectFit
            stackView.insertArrangedSubview(imageView, at: 1)
        }
        
        // Contraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])
        
        // Style
        stackView.axis = .vertical
        stackView.distribution = .fill
    }
    
    //MARK: - Background
    
    /// Add background view and blur effect to the label view
    private func addBlurBackground() {
        guard cardIndex != 1 else { return }
        
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
}

//MARK: - Content

class OverlayTableView: UITableView {
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

class OverlayPromptLabel: UILabel {
    var cardIndex: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(cardIndex: Int) {
        self.init()
        self.cardIndex = cardIndex
        labelDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func labelDidLoad() {
        self.textColor = .label
        self.font = .systemFont(ofSize: 18, weight: .regular)
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.5
        self.textAlignment = .center
        
        if cardIndex != K.OnboardOverlay.data.count - 1 {
            self.text = Z.Onboard.continuePrompt
        } else {
            self.text = Z.Onboard.finalPrompt
        }
    }
}

//MARK: - TableView Data Source

extension OnboardOverlay: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return rows for title and prompt message only if body's value is nil
        return tableViewContent[cardIndex].cellText.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .label
        cell.textLabel?.text = tableViewContent[cardIndex].cellText[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        
        // Title's text style
        if indexPath.row == 0 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
        
        // Add image to last onboard card's each cell except the first one.
        if cardIndex == tableViewContent.count - 1 {
            if indexPath.row != 0 {
                cell.imageView?.image = tableViewContent[cardIndex].cellImage?[indexPath.row - 1]
            }
        }
        
        return cell
    }
}
