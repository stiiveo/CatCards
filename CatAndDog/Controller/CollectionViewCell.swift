//
//  CollectionViewCell.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/8/11.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "CatCollectionViewCell"
    static let cellNumberPerRow: CGFloat = 3
    static let spaceBetweenCell: CGFloat = 3
//    static let width = floor(UIScreen.main.bounds.width - (spaceBetweenCell * (cellNumberPerRow - 1)) / cellNumberPerRow)
    static let width = floor((UIScreen.main.bounds.width - 3 * 2) / 3)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        widthConstraint.constant = Self.width
        print("Screen width: \(UIScreen.main.bounds.width)")
        print("Width constraint: \(Self.width)")
    }
}
