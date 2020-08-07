//
//  Constants.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    struct Data {
        static let initialImageRequestNumber: Int = 6
        static let imageRequestNumber: Int = 1
        static let maxImageNumberStored: Int = 7
    }
    struct ToolBar {
        static let height: CGFloat = 44.0
    }
    struct CardView {
        struct Style {
            static let cornerRadius: CGFloat = 20
            static let borderWidth: CGFloat = 1.0
            static let backgroundColor: UIColor = UIColor.systemGray6
        }
        struct Constraint {
            static let leading: CGFloat = 0.0
            static let trailing: CGFloat = -0.0
            static let heightToWidthRatio: CGFloat = 1.3
        }
    }
    struct ImageView {
        struct Constraint {
            static let leading: CGFloat = 5.0
            static let trailing: CGFloat = -5.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = -5.0
            static let cornerRadius: CGFloat = 20
        }
    }
}
