//
//  Constants.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    struct Color {
        static let toolbarItem = UIColor(named: "buttonColor")
    }
    struct SegueIdentifier {
        static let collectionToSingle = "collectionToSingle"
    }
    struct ButtonImage {
        static let heart = UIImage(systemName: "heart")
        static let filledHeart = UIImage(systemName: "heart.fill")
        static let trash = UIImage(systemName: "trash")
        static let share = UIImage(systemName: "square.and.arrow.up")
    }
    struct Data {
        static let initialDataRequestNumber: Int = 6
        static let dataRequestNumber: Int = 1
        static let maxDataNumberStored: Int = 7
//        static let dataToExclude = [
//            "N_54iB3Kl", "7XwqnDvi8", "cpj", "gWBdC-NJT", "VmQj-QgPi", "FID3LLZfr", "MTc2ODA1Mw", "NlctBeF8A", "0QFWQ4b_6", "gEvrbm9Z2"
//        ]
    }
    struct ToolBar {
        static let height: CGFloat = 44.0
    }
    struct CardView {
        struct Style {
            static let cornerRadius: CGFloat = 20
            static let borderWidth: CGFloat = 1.0
            static let borderColor = UIColor(named: "buttonColor")!.cgColor
            static let backgroundColor = UIColor(named: "cardBackgroundColor")
        }
        struct Constraint {
            static let leading: CGFloat = 5.0
            static let trailing: CGFloat = -5.0
            static let top: CGFloat = 40
            static let bottom: CGFloat = -40
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
