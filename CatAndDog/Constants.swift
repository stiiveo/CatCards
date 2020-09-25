//
//  Constants.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    struct SegueIdentifier {
        static let collectionToSingle = "collectionToSingle"
    }
    struct ButtonImage {
        static let heart = UIImage(systemName: "heart")
        static let filledHeart = UIImage(systemName: "heart.fill")
    }
    struct Data {
        static let initialDataRequestNumber: Int = 6
        static let dataRequestNumber: Int = 1
        static let maxDataNumberStored: Int = 7
        static let dataToExclude = ["N_54iB3Kl", "7XwqnDvi8", "cpj", "gWBdC-NJT", "VmQj-QgPi", "FID3LLZfr", "MTc2ODA1Mw", "NlctBeF8A", "0QFWQ4b_6", "gEvrbm9Z2"]
    }
    struct ToolBar {
        static let height: CGFloat = 44.0
    }
    struct CardView {
        struct Style {
            static let cornerRadius: CGFloat = 20
            static let borderWidth: CGFloat = 1.0
            static let backgroundColor: UIColor = UIColor(named: "cardBackgroundColor")!
        }
        struct Constraint {
            static let leading: CGFloat = 0.0
            static let trailing: CGFloat = -0.0
            static let yAnchorOffset: CGFloat = -20
            static let heightToWidthRatio: CGFloat = 4 / 3
        }
    }
    struct ImageView {
        struct Constraint {
            static let leading: CGFloat = 0.0
            static let trailing: CGFloat = -0.0
            static let top: CGFloat = 0.0
            static let bottom: CGFloat = -0.0
            static let cornerRadius: CGFloat = 20
        }
    }
}
