//
//  APITests.swift
//  Cat Cards Tests
//
//  Created by Jason Ou Yang on 2021/3/24.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

@testable import Cat_Cards
import XCTest

class APITests: XCTestCase {
    
    var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        urlSession = URLSession(configuration: .default)
    }

    override func tearDown() {
        urlSession = nil
        super.tearDown()
    }
    
    func sendRequestTo(urlString: String) {
        // given
        let url = URL(string: urlString)
        let promise = expectation(description: "Completion handler invoked")
        var receivedData: Data?
        var statusCode: Int?
        var responseError: Error?
        
        // when
        urlSession.dataTask(with: url!) { (data, response, error) in
            receivedData = data
            statusCode = (response as? HTTPURLResponse)?.statusCode
            responseError = error
            promise.fulfill()
        }.resume()
        
        // Wait for the response to be received within the specified time.
        wait(for: [promise], timeout: 5)
        
        // then
        XCTAssertNotNil(receivedData, "Received data is nil.")
        XCTAssertEqual(statusCode, 200, "API response code is not 200.")
        XCTAssertNil(responseError, "Failed to send request/receive response to/from API.")
    }
    
    func testResponseOfAPI() {
        sendRequestTo(urlString: K.API.urlString)
    }

}
