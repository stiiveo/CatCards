//
//  OverlayContentPickerTest.swift
//  Cat Cards Tests
//
//  Created by Jason Ou Yang on 2021/3/17.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

@testable import Cat_Cards
import XCTest

class OverlayContentPickerTest: XCTestCase {

    var picker: OverlayContentPicker!
    
    override func setUp() {
        super.setUp()
        picker = OverlayContentPicker()
    }
    
    override func tearDown() {
        picker = nil
        super.tearDown()
    }
    
    func test_trivia_returned_string_is_valid_before_reshuffle() {
        for i in (0..<K.numberOfTrivia) {
            let correctString = NSLocalizedString(picker.triviaKey + "\(i)", comment: "")
            let returnedString = picker.randomContent(contentTypes: [.trivia])
            
            XCTAssertEqual(correctString, returnedString)
        }
    }
    
    func test_quote_returned_string_is_valid_before_reshuffle() {
        for i in (0..<K.numberOfQuotes) {
            let correctString = NSLocalizedString(picker.quoteKey + "\(i)", comment: "")
            let returnedString = picker.randomContent(contentTypes: [.quote])
            
            XCTAssertEqual(correctString, returnedString)
        }
    }
    
    func test_returned_string_is_not_invalid() {
        for _ in 0..<500 {
            XCTAssertFalse(picker.randomContent(contentTypes: [.trivia]).contains("TRIVIA_"))
            
            XCTAssertFalse(picker.randomContent(contentTypes: [.quote]).contains("QUOTE_"))
        }
    }
    
    func test_same_content_is_not_picked_in_a_row() {
        for i in 0..<500 {
            let pickedString = picker.randomContent(contentTypes: [.trivia, .quote])
            let subsequentString = picker.randomContent(contentTypes: [.trivia, .quote])
            XCTAssertNotEqual(pickedString, subsequentString, "Same overlay content is picked in a row after retrieving it for \(i) time(s).")
        }
    }
    
    func test_random_content_performance() {
        measure {
            _ = picker.randomContent(contentTypes: [.trivia, .quote])
        }
    }

}
