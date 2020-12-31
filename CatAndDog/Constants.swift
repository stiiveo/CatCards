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
        static let mandyTestDeviceIdentifier = "1a0dd40a508e376308ee9345f19b1e50" // Identifier of the test device
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
            static let cornerRadius: CGFloat = 30
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
        // The difference of aspect ratio of downloaded image and the imageView
        // If the difference is bigger than this value, the imageView's content
        // mode is set to aspect fill scale, otherwise aspect fit scale.
        static let dynamicScaleThreshold: CGFloat = 0.15
    }
    
    struct Onboard {
        static let contentMargin: CGFloat = 25
        static let maxTextSize: CGFloat = 30
        struct ButtonImage {
            static let share = UIImage(systemName: "square.and.arrow.up")!
            static let undo = UIImage(systemName: "arrow.counterclockwise")!
            static let save = UIImage(systemName: "heart")!
            static let showDownloads = UIImage(systemName: "arrow.down.circle.fill")!
        }
        
        static let data = [
            // Text and images used for the onboarding card
            // Each data represents the data each card uses
            OnboardData(cellText: [Z.InstructionText.greeting,
                                   Z.InstructionText.brief,
                                   Z.InstructionText.prompt], cellImage: nil),
            OnboardData(cellText: [Z.InstructionText.buttonInstruction,
                                   Z.InstructionText.shareButton,
                                   Z.InstructionText.undoButton,
                                   Z.InstructionText.saveButton,
                                   Z.InstructionText.showDownloadsButton,
                                   Z.InstructionText.prompt],
                        cellImage: [K.Onboard.ButtonImage.share,
                                    K.Onboard.ButtonImage.undo,
                                    K.Onboard.ButtonImage.save,
                                    K.Onboard.ButtonImage.showDownloads]),
            OnboardData(cellText: [Z.InstructionText.bless,
                                   Z.InstructionText.startPrompt], cellImage: nil)
        ]
        
    }
}
