//
//  Constants.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/7/31.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import UIKit

struct K {
    typealias CompletionHandler = (Bool) -> Void
    
    struct UserDefaultsKeys {
        static let viewCount = "viewCount"
        static let onboardCompleted = "onboardCompleted"
    }
    
    struct Banner {
        static let adMobAppID = "ca-app-pub-2421510056015407~5275025170"
        static let adUnitID = "ca-app-pub-2421510056015407/2067597276" // my real ad unit ID
        static let adLoadingThreshold: Int = 9 // how many cards the user sees before loading the ad
    }
    
    struct API {
        static let urlString = "https://api.thecatapi.com/v1/images/search?mime_types=\(imageType)"
        static let imageType: String = "jpg" // Input option: 'gif', 'jpg', 'png', 'jpg,gif,png'
    }
    
    struct Color {
        static let backgroundColor = UIColor(named: "backgroundColor")
        static let tintColor = UIColor(named: "buttonColor")
        static let onboardBackground = UIColor.systemBackground
        
        // Used by gradient layer on the background
        static let lightModeColor1 = CGColor(red: 249/255, green: 228/255, blue: 192/255, alpha: 1)
        static let lightModeColor2 = CGColor(red: 246/255, green: 215/255, blue: 161/255, alpha: 1)
        static let darkModeColor1 = CGColor(red: 46/255, green: 54/255, blue: 66/255, alpha: 1)
        static let darkModeColor2 = CGColor(red: 34/255, green: 40/255, blue: 49/255, alpha: 1)
        
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
        static let defaultCacheImage = UIColor.systemGray5.image(CGSize(width: 400, height: 400)) // Default image for stackView
        static let defaultImage = UIImage(named: "default_image")! // Default image to be used if something went wrong
        static let jpegCompressionQuality: CGFloat = 0.7 // 0: lowest quality; 1: highest quality
        static let grumpyCatImageSize = CGSize(width: 1265, height: 951)
        static let savedFeedbackImage = UIImage(named: "heart_with_circle_background")!
        
        struct FolderName {
            static let fullImage = "Cat_Pictures"
            static let thumbnail = "Thumbnails"
            static let cacheImage = "Cache Images"
        }
    }
    
    struct Data {
        static let cacheDataNumber: Int = 15 // Smaller this number is, bigger the chance the user experiences the loading process
        static let undoCardNumber: Int = 9 // Number of cards the user can undo
        static let prefetchNumberOfImageAtEachSide: Int = 2 // Number of prefetched images in the stackView's arranged subviews. The value must be positive. The larger the value, the more the memory consumption will be.
        static let maxSavedImages: Int = 36 // Maximum number of pictures which can be saved to user's device
    }
    
    struct Card {
        struct SizeScale {
            static let intro: CGFloat = 0.1
            static let standby: CGFloat = 0.9
        }
        struct Style {
            static let cornerRadius: CGFloat = 30
            static let backgroundColor = UIColor(named: "cardBackgroundColor")
        }
        struct Constraint {
            static let leading: CGFloat = 15.0
            static let trailing: CGFloat = 15.0
            static let top: CGFloat = 10
            static let bottom: CGFloat = 10
        }
    }
    
    struct ImageView {
        // The difference of aspect ratio of downloaded image and the imageView
        // If the difference is bigger than this value, the imageView's content
        // mode is set to aspect fill scale, otherwise aspect fit scale.
        static let dynamicScaleThreshold: CGFloat = 0.1
        static let maximumScaleFactor: CGFloat = 4
    }
    
    struct OnboardOverlay {
        static let zoomImage = UIImage(named: "onboard_zoom_image")!
        struct ButtonImage {
            static let share = UIImage(systemName: "square.and.arrow.up")!
            static let undo = UIImage(systemName: "arrow.counterclockwise")!
            static let save = UIImage(systemName: "heart")!
            static let showDownloads = UIImage(systemName: "square.grid.2x2.fill")!
        }
        
        // Text and images used for the onboarding card
        // Each data represents the data each card uses
        static let data =
            [OnboardData(cellText: [Z.InstructionText.greetTitle,
                                   Z.InstructionText.greet_1,
                                   Z.InstructionText.greet_2],
                        cellImage: nil),
            OnboardData(cellText: [Z.InstructionText.zoomGestureTitle,
                                   Z.InstructionText.zoomInstruction],
                        cellImage: nil),
            OnboardData(cellText: [Z.InstructionText.buttonInstruction,
                                   Z.InstructionText.shareButton,
                                   Z.InstructionText.undoButton,
                                   Z.InstructionText.saveButton,
                                   Z.InstructionText.showDownloadsButton],
                        cellImage: [K.OnboardOverlay.ButtonImage.share,
                                    K.OnboardOverlay.ButtonImage.undo,
                                    K.OnboardOverlay.ButtonImage.save,
                                    K.OnboardOverlay.ButtonImage.showDownloads])
            ]
    }
    
    // Note: Sync this value to the real number of trivia content
    static let numberOfTrivia: Int = 34
    static let numberOfQuotes: Int = 11
}
