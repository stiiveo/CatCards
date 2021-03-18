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
    
    func testReturnedStringIsValid() {
        for _ in 0..<500 {
            XCTAssertFalse(picker.randomContent(contentTypes: [.trivia]).contains("TRIVIA_"))
            
            XCTAssertFalse(picker.randomContent(contentTypes: [.quote]).contains("QUOTE_"))
        }
    }
    
    func testSameContentIsNotPickedInARow() {
        for i in 0..<500 {
            let pickedString = picker.randomContent(contentTypes: [.trivia, .quote])
            let subsequentString = picker.randomContent(contentTypes: [.trivia, .quote])
            XCTAssertNotEqual(pickedString, subsequentString, "Same overlay content is picked in a row after retrieving it for \(i) time(s).")
        }
    }
    
    func testRandomContentRetrievingPerformance() {
        measure {
            _ = picker.randomContent(contentTypes: [.trivia, .quote])
        }
    }

}
