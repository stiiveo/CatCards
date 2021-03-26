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
    private var tableView: UITableView!
    private var labelView: UILabel!
    private var imageView: UIImageView?
    
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
        addBackgroundView()
        addStackView()
    }
    
    //MARK: - Stack View
    
    private func addStackView() {
        initTableView()
        initLabelView()
        
        let stackView = UIStackView(arrangedSubviews: [tableView, labelView])
        if self.cardIndex == 2 {
            initImageView()
            stackView.insertArrangedSubview(imageView!, at: 1)
        }
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
        ])
        
        // style
        stackView.axis = .vertical
        stackView.distribution = .fill
    }
    
    //MARK: - Background
    
    /// Add background view and blur effect to the label view
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
    
    //MARK: - TableView, Label, Image
    
    private func initTableView() {
        // Add tableView to onboard overlay
        tableView = UITableView()
        
        // Delegate
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Style
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
    }
    
    private func initLabelView() {
        labelView = UILabel()
        
        // Style
        labelView.textColor = .label
        labelView.font = .systemFont(ofSize: 18, weight: .regular)
        labelView.adjustsFontSizeToFitWidth = true
        labelView.minimumScaleFactor = 0.5
        labelView.textAlignment = .center
    }
    
    private func initImageView() {
        imageView = UIImageView(image: K.OnboardOverlay.tapGesture)
        imageView!.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView!.contentMode = .scaleAspectFit
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
        
        // Text messages
        cell.textLabel?.text = tableViewContent[cardIndex].cellText[indexPath.row]
        labelView.text = Z.InstructionText.prompt
        
        // Text style
        cell.textLabel?.textColor = .label
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        cell.textLabel?.numberOfLines = 0
        
        // Cell style
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = false
        
        if cardIndex == 1 {
            // Remove blur effect view of the card for zooming gesture instruction
            self.blurEffectView.removeFromSuperview()
        }
        
        // Show start prompt if it's the last onboard card.
        if cardIndex == 2 {
            if indexPath.row == 1 {
                cell.imageView?.image = tableViewContent[cardIndex].cellImage?[0]
            }
        }
        
        if cardIndex == tableViewContent.count - 1 {
            if indexPath.row != 0 {
                // Add image to each cell except the first one
                cell.imageView?.image = tableViewContent[cardIndex].cellImage?[indexPath.row - 1]
            }
            labelView.text = Z.InstructionText.startPrompt
        }
        
        if indexPath.row == 0 {
            // Title's text style
            cell.textLabel?.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        }
        
        return cell
    }
    
}
