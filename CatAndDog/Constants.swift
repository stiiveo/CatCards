//
//  Constants.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    struct UserDefaultsKeys {
        static let viewCount = "viewCount"
        static let onboardCompleted = "onboardCompleted"
        static let loadBannerAd = "loadBannerAd"
    }
    
    struct Banner {
        static let adMobAppID = "ca-app-pub-2421510056015407~5275025170"
        static let unitID = "ca-app-pub-2421510056015407/2067597276" // my real ad unit ID
        static let cardViewedToLoadBannerAd: Int = 10
        
        // TEST USE
        static let testUnitID = "ca-app-pub-3940256099942544/2934735716" // test ad unit ID
        static let myTestDeviceIdentifier = "183f37d224cd0bdff5a8ee1b7b3b7daf" // Identifier of the test device
        static let obamaTestDeviceIdentifier = "cab86adbac7f339092f5151f051e3f84" // Identifier of the test device
        static let mandyTestDeviceIdentifier = "1828f1e5516280de49d9d7b8ce165764" // Identifier of the test device
    }
    
    struct API {
        static let urlString = "https://api.thecatapi.com/v1/images/search?mime_types=\(imageType)"
        static let imageType: String = "jpg" // Input option: 'gif', 'jpg', 'png', 'jpg,gif,png'
    }
    
    struct Color {
        static let backgroundColor = UIColor(named: "backgroundColor")
        static let tintColor = UIColor(named: "buttonColor")
        static let hintViewBackground = UIColor(named: "hintView_background")
    }
    
    struct SegueIdentifiers {
        static let collectionToSingle = "collectionToSingle"
        static let mainToCollection = "mainToCollection"
    }
    
    struct ButtonImage {
        static let heart = UIImage(systemName: "heart")
        static let filledHeart = UIImage(systemName: "heart.fill")
        static let trash = UIImage(systemName: "trash")
        static let share = UIImage(systemName: "square.and.arrow.up")
    }
    
    struct Image {
        static let maxImageSize = CGSize(width: 1024, height: 1024)
        static let defaultCacheImage = UIColor.systemGray5.image(CGSize(width: 400, height: 400)) // Default image for stackView
        static let defaultImage = UIImage(named: "default_image")! // Default image to be used if something went wrong
        static let jpegCompressionQuality: CGFloat = 0.7 // 0: lowest quality; 1: highest quality
        
        struct FolderName {
            static let fullImage = "Cat_Pictures"
            static let thumbnail = "Thumbnails"
        }
    }
    
    struct Data {
//        static let maxOfCachedData: Int = 3 // TEST USE
        
        // If this value is too small, the user could have to experience more loading time.
        // However, the more the cache data, the more the memory usage is.
        // After some testing, 10 is a pretty sweat spot between UX and memory usage.
        static let maxOfCachedData: Int = 10
        static let maxBufferImageNumber: Int = 4
        static let maxSavedImages: Int = 24
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
            static let cornerRadius: CGFloat = 15
            static let backgroundColor = UIColor(named: "cardBackgroundColor")
        }
        struct Constraint {
            static let leading: CGFloat = 15.0
            static let trailing: CGFloat = -15.0
            static let top: CGFloat = 10
            static let bottom: CGFloat = -10
        }
    }
    
    struct ImageView {
        static let dynamicScaleThreshold: CGFloat = 0.15
    }
    
    struct Onboard {
        struct ButtonImage {
            static let shareButton = UIImage(systemName: "square.and.arrow.up")!
            static let undoButton = UIImage(systemName: "arrow.counterclockwise")!
            static let saveButton = UIImage(systemName: "heart")!
        }
    }
}
