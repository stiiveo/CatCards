//
//  OverlayContentPicker.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/16.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import Foundation

final class OverlayContentPicker {
    
    enum ContentType {
        case trivia, quote
    }
    
    static let shared = OverlayContentPicker()
    private var triviaCounter: Int = 0 {
        didSet {
            if triviaCounter >= K.numberOfTrivia {
                triviaCounter = 0
                shufflePickingOrder(of: .trivia)
            }
        }
    }
    private var quoteCounter: Int = 0 {
        didSet {
            if quoteCounter >= K.numberOfQuotes {
                quoteCounter = 0
                shufflePickingOrder(of: .quote)
            }
        }
    }
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
    
    /// Return a randomly picked content retrieved from the bundle.
    /// Same result will not be returned in a row.
    /// - Parameter contentTypes: Types of overlay content to be randomly picked and returned.
    /// - Returns: Randomly picked string value of specified type of content.
    func randomContent(contentTypes: [ContentType]) -> String {
        let contentType = contentTypes.randomElement()!
        var pickIndex: Int!
        switch contentType {
        case .trivia:
            pickIndex = triviaPickingOrder[triviaCounter]
            triviaCounter += 1
            
            let key = triviaKey + "\(pickIndex!)"
            let localizedTrivia = NSLocalizedString(key, comment: "A cat trivia.")
            return localizedTrivia
        case .quote:
            pickIndex = quotePickingOrder[quoteCounter]
            quoteCounter += 1
            
            let key = quoteKey + "\(pickIndex!)"
            let localizedQuote = NSLocalizedString(key, comment: "A cat quote.")
            return localizedQuote
        }
    }
    
    /// Shuffle the picking order of the specified content type.
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
