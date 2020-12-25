//
//  HintView.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/12/23.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class HintView: UIView {
    
    var cardNumber: Int = 0
    private let data = K.Onboard.data
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBackgroundView()
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
            blurEffectView.frame = self.frame
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.addSubview(blurEffectView)
        } else {
            self.backgroundColor = UIColor(named: "onboardBackground")
        }
    }
    
    func addContentView(toCard index: Int) {
        self.cardNumber = index
        
        // Add tableView to HintView
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
}

extension HintView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return rows for title and prompt message only if body's value is nil
        return data[cardNumber].cellText.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cell's text
        cell.textLabel?.text = data[cardNumber].cellText[indexPath.row]
        if cardNumber == 1 {
            // Second card
            switch indexPath.row {
            case 1:
                cell.imageView?.image = data[1].cellImage?[0]
            case 2:
                cell.imageView?.image = data[1].cellImage?[1]
            case 3:
                cell.imageView?.image = data[1].cellImage?[2]
            default:
                print("No image to be added to this cell. (Cell Number: \(indexPath.row)")
            }
        }
        
        // Style
        cell.textLabel?.textColor = .label
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.numberOfLines = 2 // max number of lines per cell
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = false
        
        // Text Style
        if indexPath.row == 0 {
            // First cell
            cell.textLabel?.font = .systemFont(ofSize: 30, weight: .regular)
        }
        if indexPath.row == data[cardNumber].cellText.count - 1 {
            // Last cell
            cell.textLabel?.font = .systemFont(ofSize: 20, weight: .medium)
            cell.textLabel?.textColor = .secondaryLabel
        }
        
        return cell
    }
    
    
}

