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
            let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
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
        
        // Cell's text and image
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
                debugPrint("No image for cell \(indexPath.row) in card \(cardNumber).")
            }
        }
        
        // Text style of cells in the middle
        cell.textLabel?.textColor = .label
        cell.textLabel?.font = .preferredFont(withTextStyle: .title2, maxSize: K.Onboard.maxTextSize)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.5
        
        cell.backgroundColor = .clear
        cell.isUserInteractionEnabled = false
        
        // Text style of first and last cell
        if indexPath.row == 0 {
            // First cell
            cell.textLabel?.font = .preferredFont(forTextStyle: .title1)
            cell.textLabel?.numberOfLines = 1
        }
        if indexPath.row == data[cardNumber].cellText.count - 1 {
            // Last cell
            cell.textLabel?.font = .preferredFont(forTextStyle: .title3)
            cell.textLabel?.textColor = .secondaryLabel
        }
        
        return cell
    }
    
    
}

extension UIFont {

  static func preferredFont(withTextStyle textStyle: UIFont.TextStyle, maxSize: CGFloat) -> UIFont {
    // Get the descriptor
    let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

    // Return a font with the minimum size
    return UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maxSize))
  }

}
