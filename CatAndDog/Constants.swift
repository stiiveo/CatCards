//
//  Constants.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    struct API {
        static let urlString = "https://api.thecatapi.com/v1/images/search?mime_types=\(imageType)"
        static let imageType: String = "jpg" // Input option: 'gif', 'jpg', 'png', 'jpg,gif,png'
    }
    
    struct Color {
        static let backgroundColor = UIColor(named: "backgroundColor")
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
    
    struct Image {
        static let maxImageSize = CGSize(width: 1024, height: 1024)
        
        struct FolderName {
            static let fullImage = "Cat_Pictures"
            static let thumbnail = "Thumbnails"
        }
    }
    
    struct Data {
//        static let maxOfCachedData: Int = 3 // TEST USE
        static let maxOfCachedData: Int = 10 // The value should be between 1 to 10
        static let maxBufferImageNumber: Int = 4
    }
    
    struct ToolBar {
        static let height: CGFloat = 44.0
    }
    
    struct CardView {
        struct Animation {
            struct Threshold {
                static let distance: CGFloat = 80
                static let speed: CGFloat = 1000
            }
        }
        struct Size {
            static let transform: CGFloat = 0.9
        }
        struct Style {
            static let cornerRadius: CGFloat = 25
            static let backgroundColor = UIColor(named: "cardBackgroundColor")
        }
        struct Constraint {
            static let leading: CGFloat = 10.0
            static let trailing: CGFloat = -10.0
            static let top: CGFloat = 10
            static let bottom: CGFloat = -10
        }
    }
    
    struct ImageView {
        static let dynamicScaleThreshold: CGFloat = 0.15
    }
}
