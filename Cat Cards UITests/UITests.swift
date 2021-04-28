//
//  UITests.swift
//  Cat Cards UITests
//
//  Created by Jason Ou Yang on 2021/3/18.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import XCTest

class UITests: XCTestCase {
    
    private let numberOfSavedImages = 5
    var toolbar: XCUIElement!
    var saveButton: XCUIElement!
    var undoButton: XCUIElement!
    var shareButton: XCUIElement!
    var goToCollectionBtn: XCUIElement!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        toolbar = XCUIApplication().toolbars["toolbar"]
        saveButton = toolbar/*@START_MENU_TOKEN@*/.buttons["saveButton"]/*[[".buttons[\"Save\"]",".buttons[\"saveButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        undoButton = toolbar/*@START_MENU_TOKEN@*/.buttons["undoButton"]/*[[".buttons[\"Undo\"]",".buttons[\"undoButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        shareButton = toolbar/*@START_MENU_TOKEN@*/.buttons["shareButton"]/*[[".buttons[\"Share\"]",".buttons[\"shareButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        goToCollectionBtn = XCUIApplication().buttons["collectionButton"]
    }

    func testHomeVC() {
        let app = XCUIApplication()
        app.launch()
        
        let currentCard = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .image).element(boundBy: 1)
        
        currentCard.tap()
        sleep(1)
        currentCard.tap()
        sleep(1)
                
        let swipeTime = numberOfSavedImages
        
        for _ in 0..<swipeTime {
            currentCard.swipeToRandomSide(velocity: 150)
            saveButton.tap()
        }
        for _ in 0..<swipeTime {
            undoButton.tap()
        }
        
        shareButton.tap()
        app/*@START_MENU_TOKEN@*/.navigationBars["UIActivityContentView"]/*[[".otherElements[\"ActivityListView\"].navigationBars[\"UIActivityContentView\"]",".navigationBars[\"UIActivityContentView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Close"].tap()
        saveButton.tap()
    }
    
    func testSegue() {
        let app = XCUIApplication()
        app.activate()
        
        saveButton.tap()
        if app.alerts.count != 0 {
            app.alerts["Storage is full."].scrollViews.otherElements.buttons["OK"].tap()
        }
        
        goToCollectionBtn.tap()
        app.collectionViews.cells.images.firstMatch.tap()
        app.navigationBars["CatCards.SingleImageVC"].buttons["Back"].tap()
        app.navigationBars["CatCards.CollectionVC"].buttons["Back"].tap()
    }
    
    func testSingleImageVC() {
        let app = XCUIApplication()
        app.activate()
        
        // Navigate to SingleImageVC.
        goToCollectionBtn.tap()
        app.collectionViews.cells.images.firstMatch.tap()
        
        // Test tap and pinch gesture recognizers.
        let firstImage = app.scrollViews.images.firstMatch
        firstImage.doubleTap()
        firstImage.pinch(withScale: 2.0, velocity: 30)
        firstImage.doubleTap()
        
        // Test scrollView
        for i in 0..<numberOfSavedImages {
            app.scrollViews.images.allElementsBoundByIndex[i].swipeLeft()
        }
        
        for j in 0..<numberOfSavedImages {
            app.scrollViews.images.allElementsBoundByIndex[numberOfSavedImages - j].swipeRight()
        }
        
        // Test share sheet and image deletion.
        let toolbar = app.toolbars["Toolbar"]
        toolbar.buttons["Share"].tap()
        app/*@START_MENU_TOKEN@*/.navigationBars["UIActivityContentView"]/*[[".otherElements[\"ActivityListView\"].navigationBars[\"UIActivityContentView\"]",".navigationBars[\"UIActivityContentView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Close"].tap()
        toolbar.buttons["Delete"].tap()
        app.sheets["This action can not be reverted."].scrollViews.otherElements.buttons["Delete Picture"].tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
}

extension XCUIElement {
    enum SwipeSide: CaseIterable {
        case right, left, up, down
    }
    
    func swipeToRandomSide(velocity: XCUIGestureVelocity) {
        let randomSide = SwipeSide.allCases.randomElement()!
        switch randomSide {
        case .right:
            self.swipeRight(velocity: velocity)
        case .left:
            self.swipeLeft(velocity: velocity)
        case .up:
            self.swipeUp(velocity: velocity)
        case .down:
            self.swipeDown(velocity: velocity)
        }
    }
}
