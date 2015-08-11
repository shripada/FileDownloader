//
//  URLDownloaderTests.swift
//  URLDownloaderTests
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import UIKit
import XCTest

class URLDownloaderTests: XCTestCase {

    //files to be downloaded
  let filesTobeDownloaded = [
    "http://kmmc.in/wp-content/uploads/2014/01/lesson2.pdf",
    "http://fzs.sve-mo.ba/sites/default/files/dokumenti-vijesti/sample.pdf"
]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
