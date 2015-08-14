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
    //Remove cache.
    var semaphore = dispatch_semaphore_create(0)
    FileDownloadManager.sharedInstance.cache.removeAllObjects { () -> Void in
      dispatch_semaphore_signal(semaphore)
    };

    dispatch_semaphore_wait(semaphore, 20)

    super.tearDown()
  }

  func testFreshDownload() {


    let expectation = expectationWithDescription("\(filesTobeDownloaded[0])")
    //Remove any cache forcefully.
    var cacheDir = FileDownloadManager.cacheDirectory as NSString
    if  let cacheInfo = FileDownloadManager.sharedInstance.cache.objectForKey(filesTobeDownloaded[0]),
        let fileName = cacheInfo["fileName"] as? String
    {
      let cacheFilePath = cacheDir.stringByAppendingPathComponent(fileName)
      if(NSFileManager.defaultManager().fileExistsAtPath(cacheFilePath)){
        NSFileManager.defaultManager().removeItemAtPath(cacheFilePath, error: nil)
      }
    }



    let download = FileDownloadManager.sharedInstance.download(filesTobeDownloaded[0]){
      [unowned self] (url, filePath, success, error) in
      XCTAssertNil(error, "Failed!: Download failed with an error")
      XCTAssertNotNil(filePath, "Failed!: Could not get the file downloaded!")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(40, handler: nil)

  }

  func testCachedFetch()
  {
    //Ensure we have a cache entry already.
    testFreshDownload()


    let expectation = expectationWithDescription("\(filesTobeDownloaded[0])")

    var creationDate : NSDate?
    var  cacheFilePath:String?

    var cacheDir = FileDownloadManager.cacheDirectory as NSString
    if  let cacheInfo = FileDownloadManager.sharedInstance.cache.objectForKey(filesTobeDownloaded[0]),
      let fileName = cacheInfo["fileName"] as? String
    {
      cacheFilePath = cacheDir.stringByAppendingPathComponent(fileName)
      if let attributes:NSDictionary = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        creationDate = attributes[NSFileCreationDate] as? NSDate
      }

    }

    let download = FileDownloadManager.sharedInstance.download(filesTobeDownloaded[0]){
      [unowned self] (url, filePath, success, error) in
      XCTAssertNil(error, "Failed!: Download failed with an error")
      XCTAssertNotNil(filePath, "Failed!: Could not get the file downloaded!")

      //Check again that, the file was not overwritten by an actual download. Creation date should not have change now.
      if let attributes:NSDictionary  = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        let newCreationDate = attributes[NSFileCreationDate] as? NSDate
        XCTAssertEqual(creationDate!, newCreationDate!, "Failed!, cached file was not returned!")
      }

      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(10, handler: nil)

  }

  func testETagChangedShouldTriggerAFreshDownload()
  {
    //Ensure we have a cache entry already.
    testFreshDownload()

    //Simulate a different ETag, by changing the corresponing entry in the cache.
    var creationDate : NSDate?
    var  cacheFilePath:String?

    var cacheDir = FileDownloadManager.cacheDirectory as NSString
    if  let cacheInfo:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(filesTobeDownloaded[0]) ,
      let fileName = cacheInfo["fileName"] as? String
    {
      cacheFilePath = cacheDir.stringByAppendingPathComponent(fileName)
      if let attributes:NSDictionary = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        creationDate = attributes[NSFileCreationDate] as? NSDate
      }

      var newCacheInfo : [String:String] =  ["lastModified" : cacheInfo["lastModified"] as! String , "ETag" : "ChangedValue", "fileName" : fileName ]
      FileDownloadManager.sharedInstance.cache.setObject(newCacheInfo, forKey: filesTobeDownloaded[0])

    }

    let expectation = expectationWithDescription("ETagChnages for \(filesTobeDownloaded[0])")


    let download = FileDownloadManager.sharedInstance.download(filesTobeDownloaded[0]){
      [unowned self] (url, filePath, success, error) in
      XCTAssertNil(error, "Failed!: Download failed with an error")
      XCTAssertNotNil(filePath, "Failed!: Could not get the file downloaded!")

      //Check again that, the file was not overwritten by an actual download. Creation date should not have change now.
      if let attributes:NSDictionary  = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        let newCreationDate = attributes[NSFileCreationDate] as? NSDate
        XCTAssertNotEqual(creationDate!, newCreationDate!, "Failed!, new file was not overwritten despite ETag change!")
      }

      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(50, handler: nil)



  }

  func testModifiedDateChangedShouldTriggerAFreshDownload()
  {
    //Ensure we have a cache entry already.
    testFreshDownload()

    //Simulate an old time stamp for our file than that of server.
    var creationDate : NSDate?
    var  cacheFilePath:String?

    var cacheDir = FileDownloadManager.cacheDirectory as NSString
    if  let cacheInfo:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(filesTobeDownloaded[0]) ,
      let fileName = cacheInfo["fileName"] as? String
    {
      cacheFilePath = cacheDir.stringByAppendingPathComponent(fileName)
      if let attributes:NSDictionary = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        creationDate = attributes[NSFileCreationDate] as? NSDate
      }

      let oldModifiedDate  = "Fri, 12 May 2014 04:42:17 GMT" //Fri, 16 May 2014 04:42:17 GMT

      var newCacheInfo : [String:String] =  ["lastModified" : oldModifiedDate , "ETag" : cacheInfo["ETag"] as! String, "fileName" : fileName ]
      FileDownloadManager.sharedInstance.cache.setObject(newCacheInfo, forKey: filesTobeDownloaded[0])

    }

    let expectation = expectationWithDescription("ETagChnages for \(filesTobeDownloaded[0])")


    let download = FileDownloadManager.sharedInstance.download(filesTobeDownloaded[0]){
      [unowned self] (url, filePath, success, error) in
      XCTAssertNil(error, "Failed!: Download failed with an error")
      XCTAssertNotNil(filePath, "Failed!: Could not get the file downloaded!")

      //Check again that, the file was not overwritten by an actual download. Creation date should not have change now.
      if let attributes:NSDictionary  = NSFileManager.defaultManager().attributesOfItemAtPath(cacheFilePath!, error: nil){
        let newCreationDate = attributes[NSFileCreationDate] as? NSDate
        XCTAssertNotEqual(creationDate!, newCreationDate!, "Failed!, new file was not overwritten despite last modified dates differ!")
      }

      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(50, handler: nil)
    
    
    
  }



}
