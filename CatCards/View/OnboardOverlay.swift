//
//  OnboardOverlay.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/12/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class OnboardOverlay: UIView {
    
    var cardNumber: Int = 0
    private lazy var blurEffectView = UIVisualEffectView()
    private lazy var labelView = UILabel()
    private let data = K.Onboard.data
    
    //MARK: - Init Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundView()
        addLabelView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Overlay Background
    
    /// Add background view and blur effect to the label view
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
    
    //MARK: - Addition of Text Info
    
    func addTableView(toCard index: Int) {
        self.cardNumber = index
        
        // Add tableView to onboard overlay
        let tableView = UITableView()
        self.addSubview(tableView)
        
        // Set the origin and size of the tableView
        let margin = K.Onboard.contentMargin
        let tableViewFrame = CGRect(
            x: self.frame.origin.x + margin,
            y: self.frame.origin.y + margin,
            width: self.frame.width - margin * 2,
            height: self.frame.height - margin * 2
        )
        tableView.frame = tableViewFrame
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Delegate
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Style
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
    }
    
    private func addLabelView() {
        self.addSubview(self.labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            labelView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40),
        ])
        
        // Style
        labelView.textColor = .label
        labelView.font = .systemFont(ofSize: 18, weight: .regular)
        labelView.adjustsFontSizeToFitWidth = true
        labelView.minimumScaleFactor = 0.5
    }
}

//MARK: - TableView Data Source

extension OnboardOverlay: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return rows for title and prompt message only if body's value is nil
        return data[cardNumber].cellText.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Text messages
        cell.textLabel?.text = data[cardNumber].cellText[indexPath.row]
        labelView.text = Z.InstructionText.prompt
        
        // Text style
        cell.textLabel?.textColor = .label
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        cell.textLabel?.numberOfLines = 0
        
        // Cell style
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = false
        
        if cardNumber == 1 {
            // Remove blur effect view of the card for zooming gesture instruction
            self.blurEffectView.removeFromSuperview()
        }
        
        if cardNumber == 2 {
            // Last card's cell images
            if indexPath.row != 0 {
                // Add image to each cell except the first and the last one
                cell.imageView?.image = data[2].cellImage?[indexPath.row - 1]
            }
            // Label view text message
            labelView.text = Z.InstructionText.startPrompt
        }
        
        if indexPath.row == 0 {
            // Title's text style
            cell.textLabel?.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
        
        return cell
    }
    
}
