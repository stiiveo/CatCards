//
//  OverlayContentPicker.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/16.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import Foundation

/// This class contains a method which can be used to randomly pick one of the trivia or quote localized string values, which are stored in the folder 'Localizable.strings'.
class OverlayContentPicker {
    
    enum ContentType {
        case trivia, quote
    }
    
    static let shared = OverlayContentPicker()
    private var triviaCounter: Int = 0
    private var quoteCounter: Int = 0
    private let triviaKey = "TRIVIA_"
    private let quoteKey = "QUOTE_"
    
    // Initiate an shuffled array which contains incrementing integer starting from 0 to the last number of the trivia content.
    private var triviaPickingOrder: [Int] = {
        let indexArray = (0..<K.numberOfTrivia).map { index in
            return index
        }
        return indexArray.shuffled()
    }()
    
    // Initiate an shuffled array which contains incrementing integer starting from 0 to the last number of the quote content.
    private var quotePickingOrder: [Int] = {
        let indexArray = (0..<K.numberOfQuotes).map { index in
            return index
        }
        return indexArray.shuffled()
    }()
    
    /// Return seemingly randomized and localized trivia or quote string from the bundle's folder Localizable.strings where the returned string will be different the next time this method is called if the same class is referenced again.
    /// - Returns: Randomly picked a trivia or quote string where if the method is called again via the same class, the returned string value will Not be the same as the previous returned one.
    func randomContent(contentTypes: [ContentType]) -> String {
        let contentType = contentTypes.randomElement()!
        var pickIndex: Int!
        switch contentType {
        case .trivia:
            if triviaCounter >= K.numberOfTrivia {
                shufflePickingOrder(of: .trivia)
                triviaCounter = 0
            }
            pickIndex = triviaPickingOrder[triviaCounter]
            triviaCounter += 1
            
            let key = triviaKey + "\(pickIndex!)"
            let localizedTrivia = NSLocalizedString(key, comment: "A cat trivia.")
            return localizedTrivia
        case .quote:
            if quoteCounter >= K.numberOfQuotes {
                shufflePickingOrder(of: .quote)
                quoteCounter = 0
            }
            pickIndex = quotePickingOrder[quoteCounter]
            quoteCounter += 1
            
            let key = quoteKey + "\(pickIndex!)"
            let localizedQuote = NSLocalizedString(key, comment: "A cat quote.")
            return localizedQuote
        }
    }
    
    /// Shuffle previously shuffled content picking order.
    /// This method makes sure that the same content will not be picked after the order is shuffled. E.g. if the last picking index is 2, the first picking index of the re–shuffled picking order will not be 2.
    /// - Parameter contentType: Which content type's picking order to shuffle.
    private func shufflePickingOrder(of contentType: ContentType) {
        switch contentType {
        case .trivia:
            let oldOrder = triviaPickingOrder
            while oldOrder == triviaPickingOrder {
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastPick = triviaPickingOrder.last!
                triviaPickingOrder.removeLast()
                
                triviaPickingOrder.shuffle()
                triviaPickingOrder.insert(lastPick, at: triviaPickingOrder.count / 2)
            }
        case .quote:
            let oldOrder = quotePickingOrder
            while oldOrder == quotePickingOrder {
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastIndex = quotePickingOrder.last!
                quotePickingOrder.removeLast()
                quotePickingOrder.shuffle()
                quotePickingOrder.insert(lastIndex, at: quotePickingOrder.count / 2)
            }
        }
    }
}
