//
//  OverlayContentPicker.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/3/16.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import Foundation

final class OverlayContentPicker {
    
    static let shared = OverlayContentPicker()
    private init() {}
    
    // MARK: - Properties
    
    enum ContentType {
        case trivia, quote
    }
    
    // Shuffled trivia picking order.
    private var triviaPickingOrder: [Int] = {
        return (0..<K.numberOfTrivia).map { $0 }.shuffled()
    }()
    
    // Shuffled quote picking order.
    private var quotePickingOrder: [Int] = {
        return (0..<K.numberOfQuotes).map { $0 }.shuffled()
    }()
    
    private var triviaPickingCounter: Int = 0 {
        didSet {
            if triviaPickingCounter >= K.numberOfTrivia {
                triviaPickingCounter = 0
                shufflePickingOrder(of: .trivia)
            }
        }
    }
    private var quotePickingCounter: Int = 0 {
        didSet {
            if quotePickingCounter >= K.numberOfQuotes {
                quotePickingCounter = 0
                shufflePickingOrder(of: .quote)
            }
        }
    }
    private let triviaKey = "TRIVIA_"
    private let quoteKey = "QUOTE_"
    
    // MARK: - Public Methods
    
    /// Return a randomly picked content retrieved from the bundle.
    /// Same result will not be returned in a row.
    /// - Parameter contentTypes: Types of overlay content to be randomly picked and returned.
    /// - Returns: Randomly picked string value of specified type of content.
    func randomContent(contentTypes: [ContentType]) -> String {
        guard let contentType = contentTypes.randomElement() else { return "" }
        var pickIndex: Int!
        switch contentType {
        case .trivia:
            pickIndex = triviaPickingOrder[triviaPickingCounter]
            triviaPickingCounter += 1
            
            let key = triviaKey + "\(pickIndex!)"
            let localizedTrivia = NSLocalizedString(key, comment: "A cat trivia.")
            return localizedTrivia
        case .quote:
            pickIndex = quotePickingOrder[quotePickingCounter]
            quotePickingCounter += 1
            
            let key = quoteKey + "\(pickIndex!)"
            let localizedQuote = NSLocalizedString(key, comment: "A cat quote.")
            return localizedQuote
        }
    }
    
    // MARK: - Private Methods
    
    /// Shuffle the picking order of the specified content type.
    /// - Parameter contentType: Which content type's picking order to shuffle.
    private func shufflePickingOrder(of contentType: ContentType) {
        switch contentType {
        case .trivia:
            reshufflePickingOrder(&triviaPickingOrder)
        case .quote:
            reshufflePickingOrder(&quotePickingOrder)
        }
    }
    
    /// Re-shuffle the existing picking order.
    /// - Parameter order: The picking order to be shuffled with the last element moved to the center position of the resultant shuffled collection.
    private func reshufflePickingOrder( _ order: inout [Int]) {
        guard order.count > 2 else { return }
        
        let lastPick = order.last!
        order.removeLast()
        order.shuffle()
        // Move the last element to the center position of the re–shuffled array.
        order.insert(lastPick, at: order.count / 2)
    }
}
