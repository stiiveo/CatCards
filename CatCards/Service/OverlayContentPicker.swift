//
//  OverlayContentPicker.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/16.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import Foundation

class OverlayContentPicker {
    
    private enum ContentType {
        case trivia, quote
    }
    
    static let shared = OverlayContentPicker()
    private var triviaCounter: Int = 0
    private var quoteCounter: Int = 0
    private var triviaShuffledIndex: [Int] = {
        let indexArray = (0..<K.numberOfTrivia).map { index in
            return index
        }
        return indexArray.shuffled()
    }()

    private var quoteShuffledIndex: [Int] = {
        let indexArray = (0..<K.numberOfQuotes).map { index in
            return index
        }
        return indexArray.shuffled()
    }()
    
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
    
    private func shuffledIndex(contentType type: ContentType) -> Int {
        let counter = type == .quote ? quoteCounter : triviaCounter
        let numberOfContent = type == .quote ? K.numberOfQuotes : K.numberOfTrivia
        
        guard counter < numberOfContent else {
            switch type {
            case .quote:
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastIndex = quoteShuffledIndex.last!
                quoteShuffledIndex.removeLast()
                quoteShuffledIndex.shuffle()
                quoteShuffledIndex.insert(lastIndex, at: quoteShuffledIndex.count / 2)
                quoteCounter = 1
                
                return quoteShuffledIndex[0]
            case .trivia:
                // Remove the last element from the array and put it back to the center position of the re–shuffled array.
                let lastIndex = triviaShuffledIndex.last!
                triviaShuffledIndex.removeLast()
                triviaShuffledIndex.shuffle()
                triviaShuffledIndex.insert(lastIndex, at: triviaShuffledIndex.count / 2)
                triviaCounter = 1
                
                return triviaShuffledIndex[0]
            }
        }
        
        var pickedIndex: Int!
        switch type {
        case .quote:
            pickedIndex = quoteCounter
            quoteCounter += 1
        case .trivia:
            pickedIndex = triviaCounter
            triviaCounter += 1
        }
        return pickedIndex
    }
}
