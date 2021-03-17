//
//  OverlayContentPicker.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/16.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import Foundation

/// This class contains a method which can be used to randomly pick one of the trivia or quote localized string values, which are stored in the folder [Localizable.strings].
class OverlayContentPicker {
    
    private enum ContentType {
        case trivia, quote
    }
    
    static let shared = OverlayContentPicker()
    private var triviaCounter: Int = 0
    private var quoteCounter: Int = 0
    
    // Initiate an shuffled array which contains incrementing integer starting from 0 to the last number of the trivia content.
    private var triviaShuffledIndex: [Int] = {
        let indexArray = (0..<K.numberOfTrivia).map { index in
            return index
        }
        return indexArray.shuffled()
    }()
    
    // Initiate an shuffled array which contains incrementing integer starting from 0 to the last number of the quote content.
    private var quoteShuffledIndex: [Int] = {
        let indexArray = (0..<K.numberOfQuotes).map { index in
            return index
        }
        return indexArray.shuffled()
    }()
    
    /// Return seemingly randomized localized trivia or quote string from the bundle's folder Localizable.strings where the returned string will be different the next time this method is called if the same class is referenced again.
    /// - Returns: Randomly picked trivia or quote where if the method is called again via the same class, the returned string value will Not be the same as the previous returned one.
    func randomCatTriviaOrQuote() -> String {
        let contentType: ContentType = (0...1).randomElement()! % 2 == 0 ? .trivia : .quote
        let index = shuffledIndex(contentType: contentType)
        switch contentType {
        case .quote:
            let key = "QUOTE_" + "\(index)"
            let localizedQuote = NSLocalizedString(key, comment: "A cat quote.")
            return localizedQuote
        case .trivia:
            let key = "TRIVIA_" + "\(index)"
            let localizedTrivia = NSLocalizedString(key, comment: "A cat trivia.")
            return localizedTrivia
        }
    }
    
    /// Return a subscript index from the beginning of the already shuffled trivia / quote shuffled index array accordingly.
    /// If the last subscript index had already been returned, re–shuffle the index array and return the subscript index from the start again, until the last subscript index is return again. So on and so forth.
    /// - Parameter type: From which type of shuffled index array to return the subscript index.
    /// - Returns: The picked subscript index which can be used to get the localized overlay string content.
    private func shuffledIndex(contentType type: ContentType) -> Int {
        let counter = type == .trivia ? triviaCounter : quoteCounter
        let numberOfContent = type == .trivia ? K.numberOfTrivia : K.numberOfQuotes
        
        guard counter < numberOfContent else {
            switch type {
            case .trivia:
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastIndex = triviaShuffledIndex.last!
                triviaShuffledIndex.removeLast()
                triviaShuffledIndex.shuffle()
                triviaShuffledIndex.insert(lastIndex, at: triviaShuffledIndex.count / 2)
                triviaCounter = 1
                
                return triviaShuffledIndex[0]
            case .quote:
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastIndex = quoteShuffledIndex.last!
                quoteShuffledIndex.removeLast()
                quoteShuffledIndex.shuffle()
                quoteShuffledIndex.insert(lastIndex, at: quoteShuffledIndex.count / 2)
                quoteCounter = 1
                
                return quoteShuffledIndex[0]
            }
        }
        
        var pickedIndex: Int!
        switch type {
        case .trivia:
            pickedIndex = triviaCounter
            triviaCounter += 1
        case .quote:
            pickedIndex = quoteCounter
            quoteCounter += 1
        }
        return pickedIndex
    }
}
