//
//  UITests.swift
//  Cat Cards UITests
//
//  Created by Jason Ou Yang on 2021/3/18.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

/*
 Important: Make sure the onboard session is completed
 and no image is saved yet before conducting full test.
 */

import XCTest

class UITests: XCTestCase {
    
    var toolbar: XCUIElement!
    var saveButton: XCUIElement!
    var undoButton: XCUIElement!
    var shareButton: XCUIElement!
    var goToCollectionButton: XCUIElement!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        toolbar = XCUIApplication().toolbars["toolbar"]
        saveButton = toolbar/*@START_MENU_TOKEN@*/.buttons["saveButton"]/*[[".buttons[\"Save\"]",".buttons[\"saveButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        undoButton = toolbar/*@START_MENU_TOKEN@*/.buttons["undoButton"]/*[[".buttons[\"Undo\"]",".buttons[\"undoButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        shareButton = toolbar/*@START_MENU_TOKEN@*/.buttons["shareButton"]/*[[".buttons[\"Share\"]",".buttons[\"shareButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        goToCollectionButton = XCUIApplication().buttons["collectionButton"]
        
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()
    }
    
    override func tearDown() {
        toolbar = nil
        saveButton = nil
        undoButton = nil
        shareButton = nil
        goToCollectionButton = nil
        super.tearDown()
    }
    
    func testTapToToggleOverlay() {
        let app = XCUIApplication()
        app.launchArguments = ["enable-overlay"]
        let currentCardImageView = app.images.element(boundBy: 1)
        
        XCTAssertTrue(currentCardImageView.descendants(matching: .other).firstMatch.exists)
        
        currentCardImageView.tap()
        XCTAssertFalse(currentCardImageView.descendants(matching: .other).firstMatch.exists)
        
        currentCardImageView.tap()
        XCTAssertTrue(currentCardImageView.descendants(matching: .other).firstMatch.exists)
    }
    
    func testPinchToZoomIn() {
        let app = XCUIApplication()
        let currentCard = app.otherElements.element(boundBy: 1)
        currentCard.pinch(withScale: 2.0, velocity: 5)
    }

    func testSwipeToDismiss() {
        let app = XCUIApplication()
        var topCard: XCUIElement { return app.otherElements.element(boundBy: 1) }
        
        // Test swiping gesture to each side of the screen
        let card0 = topCard
        card0.swipeRight()
        sleep(1)
        XCTAssertNotEqual(topCard, card0)
        
        let card1 = topCard
        card1.swipeLeft()
        sleep(1)
        XCTAssertNotEqual(topCard, card1)
        
        let card2 = topCard
        card2.swipeUp()
        sleep(1)
        XCTAssertNotEqual(topCard, card2)
        
        let card3 = topCard
        card3.swipeDown()
        sleep(1)
        XCTAssertNotEqual(topCard, card3)
    }
    
    func testToolBarButtons() {
        let app = XCUIApplication()
        let currentCard = app.otherElements.element(boundBy: 1)
        currentCard.swipeLeft()
        undoButton.tap()
        shareButton.tap()
        app.buttons["Close"].tap()
        saveButton.tap()
    }
    
    func testSegue() {
        let app = XCUIApplication()
        saveButton.tap()
        if app.alerts.count != 0 {
            app.buttons["OK"].tap()
        }
        
        goToCollectionButton.tap()
        XCTAssert(app.navigationBars["CatCards.CollectionVC"].exists)
        
        app.collectionViews.cells.images.firstMatch.tap()
        XCTAssert(app.navigationBars["CatCards.SingleImageVC"].exists)
        
        app.buttons["Back"].tap()
        XCTAssert(app.navigationBars["CatCards.CollectionVC"].exists)
        
        app.buttons["Back"].tap()
        XCTAssert(app.navigationBars["CatCards.HomeVC"].exists)
    }
    
    func testSingleImageVC() {
        let app = XCUIApplication()
        saveButton.tap()
        // Navigate to SingleImageVC.
        goToCollectionButton.tap()
        
        let savedImage = app.collectionViews.cells.images.firstMatch
        savedImage.tap()
        
        // Test tap, pinch and pan gestures
        let image = app.scrollViews.images.firstMatch
        image.doubleTap()
        image.pinch(withScale: 1.2, velocity: 5)
        image.press(forDuration: 1.0, thenDragTo: app.buttons["Back"])
        image.doubleTap()
        
        // Test scrollView
        for _ in 0..<5 {
            app.scrollViews.firstMatch.swipeLeft()
        }

        for _ in 0..<5 {
            app.scrollViews.firstMatch.swipeRight()
        }
        
        // Test functionalities of the toolbar's buttons
        let toolbar = app.toolbars["Toolbar"]
        toolbar.buttons["Share"].tap()
        app.buttons["Close"].tap()
        toolbar.buttons["Delete"].tap()
        app.buttons["Delete Picture"].tap()
        app.buttons["Back"].tap()
        
        // Test the image is deleted
        XCTAssertFalse(app.collectionViews.cells.images.firstMatch == savedImage)
    }
    
}
