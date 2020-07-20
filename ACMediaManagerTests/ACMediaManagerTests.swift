//
//  ACMediaManagerTests.swift
//  ACMediaManagerTests
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//

import XCTest
@testable import ACMediaManager

class ACMediaManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testMyMethod(){
        let test = TestClass()
        
        XCTAssertEqual(test.test(), "Test Tests")
        
    }

}
