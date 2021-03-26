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
    
    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    func testHomeVC() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let currentCard = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .image).element(boundBy: 1)
        
        currentCard.tap()
        sleep(1)
        currentCard.tap()
        sleep(1)
        
        let swipeTime = numberOfSavedImages
        let toolbar = app.toolbars["Toolbar"]
        let saveButton = toolbar/*@START_MENU_TOKEN@*/.buttons["saveButton"]/*[[".buttons[\"Save\"]",".buttons[\"saveButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let undoButton = toolbar/*@START_MENU_TOKEN@*/.buttons["undoButton"]/*[[".buttons[\"Undo\"]",".buttons[\"undoButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let shareButton = toolbar/*@START_MENU_TOKEN@*/.buttons["shareButton"]/*[[".buttons[\"Share\"]",".buttons[\"shareButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        
        for _ in 0..<swipeTime {
            currentCard.swipeToRandomSide(velocity: 150)
            sleep(1)
            saveButton.tap()
        }
        
        
        for _ in 0..<swipeTime {
            undoButton.tap()
            sleep(1)
        }
        
        
        shareButton.tap()
        app/*@START_MENU_TOKEN@*/.navigationBars["UIActivityContentView"]/*[[".otherElements[\"ActivityListView\"].navigationBars[\"UIActivityContentView\"]",".navigationBars[\"UIActivityContentView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Close"].tap()
        
        toolbar/*@START_MENU_TOKEN@*/.buttons["saveButton"]/*[[".buttons[\"Save\"]",".buttons[\"saveButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
    }
    
    func testSegue() {
        let app = XCUIApplication()
        app.activate()
        sleep(5)
        
        app.toolbars["Toolbar"]/*@START_MENU_TOKEN@*/.buttons["saveButton"]/*[[".buttons[\"Save\"]",".buttons[\"saveButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        
        if app.alerts.count != 0 {
            app.alerts["Storage is full."].scrollViews.otherElements.buttons["OK"].tap()
            sleep(1)
        }
        
        
        app.navigationBars["CatCards.HomeVC"]/*@START_MENU_TOKEN@*/.buttons["collectionButton"]/*[[".buttons[\"grid 2x2\"]",".buttons[\"collectionButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        app.collectionViews.cells.images.firstMatch.tap()
        sleep(1)
        app.navigationBars["CatCards.SingleImageVC"].buttons["Back"].tap()
        sleep(1)
        app.navigationBars["CatCards.CollectionVC"].buttons["Back"].tap()
        sleep(1)
        
    }
    
    func testSingleImageVC() {
        let app = XCUIApplication()
        app.activate()
        
        // Navigate to SingleImageVC.
        app.navigationBars["CatCards.HomeVC"]/*@START_MENU_TOKEN@*/.buttons["collectionButton"]/*[[".buttons[\"grid 2x2\"]",".buttons[\"collectionButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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
