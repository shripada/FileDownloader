//
//  DownloadManager.swift
//  URLDownloader
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import Foundation

/**
   This class creates the necessary download tasks internally for each download request
  creates a FileDownload object and returns it to caller to perform cancel operation, or resume
  a canceled or failed download.
*/

 public class DownloadManager {

  public typealias DownLoadCompletionHandler = (filePath: String?, success: Bool, error: NSError?)-> Void

   static let sharedInstance : DownloadManager = {
    var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    //Set up a cache of 4M in memory and 60 MB disk
    let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 60 * 1024 * 1024, diskPath:nil)
    sessionConfig.URLCache = URLCache


    return DownloadManager(configuration: sessionConfig)
  }()

  //Directory where cached files are written.
  let cacheDirectory : String = {

    var bundle: String = "Unknown"

    if let info = NSBundle.mainBundle().infoDictionary {
      bundle = info[kCFBundleIdentifierKey] as! String
    }

    let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as! String
    let dir = cacheDirectory.stringByAppendingFormat("%@", bundle)

    return dir
  }()


  /// The underlying session.
  let session: NSURLSession

  /**
    Designated initializer
  
    :param: configuration Session configuration
  */

  required  public init(configuration: NSURLSessionConfiguration)
  {
    self.session  = NSURLSession(configuration: configuration)
  }

  deinit {
    session.invalidateAndCancel()
  }

   //MARK: API

/**
  Initiates an asynchronous download for each of the url mentioned, with a completion handler, that
  gets called for each of the successful download.
  
  :param: url  The url as a String
  :param:  completion  Closure that will be called for download associated when the request is completed.
  :result: Returns the FileDownload object that encapsulates the task underneath.
*/

  func download( url :String, _ completion:DownLoadCompletionHandler )-> FileDownload{

    //This internally creates the download task needed. 
    return FileDownload(session: session, url: url, completion)
  }
}
