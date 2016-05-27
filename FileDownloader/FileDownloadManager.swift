//
//  FileDownloadManager.swift
//  Version 1.0.1
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

public class FileDownloadManager {

  public typealias DownLoadCompletionHandler = (url:String, filePath: String?, success: Bool, error: NSError?)-> Void

  static let sharedInstance : FileDownloadManager = {
    var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    //We will manage caching ourselves, dont want session to cache.
    sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
    return FileDownloadManager(configuration: sessionConfig)
    }()

  var activeDownloadsDict : [String:FileDownload] = [:]

  //Directory where cached files are written.
  static var cacheDirectory : String = {

    var bundle: String = "Unknown"

    if let info = NSBundle.mainBundle().infoDictionary {
      bundle = info[String(kCFBundleIdentifierKey)] as! String
    }

    let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first

    //Create a caches folder for the app if does not exist in caches directory.
    let dir = (cacheDirectory! as NSString).stringByAppendingPathComponent(bundle)

    if(!NSFileManager.defaultManager().fileExistsAtPath(dir)){
      do {
        try NSFileManager.defaultManager() .createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
      } catch _ {
      }
    }

    return dir
    }()

  //We want to store the last-modified date of a request, and also, the cache file path, where the pdf file is stored. The cache gets created within the default caches folder, so we dont need to really worry
  //about explicitely removing expired objects, or set expiry for cached objects. iOS will purge cache if need arises.
  public let cache = Cache<NSDictionary>(name: "DownloaderCache", directory: cacheDirectory)


  /// The underlying session.
  let session: NSURLSession

  /**
  Designated initializer

  - parameter configuration: Session configuration
  */

  required  public init(configuration: NSURLSessionConfiguration){
    self.session  = NSURLSession(configuration: configuration)
  }

  deinit {
    session.invalidateAndCancel()
  }

  //MARK: API

  /**
  Initiates an asynchronous download for each of the url mentioned, with a completion handler, that
  gets called for each of the successful download. Download will start immediately.

  - parameter url:  The url as a String
  - parameter  completion:  Closure that will be called for download associated when the request is completed.
  :result: Returns the FileDownload object that encapsulates the task underneath.
  */

  func download( url :String, _ completion:DownLoadCompletionHandler )-> FileDownload{

    //This internally creates the download task needed.
    return download(url, resumeImmediately:true, completion)
  }

  /**
  Initiates an asynchronous download for each of the url mentioned, with a completion handler, that
  gets called for each of the successful download. Additionally allows if the donwload should begin immediately or not.

  - parameter url:  The url as a String
  - parameter resumesImmediately:  Set true, if the download should begin immediately, fasle otherwise.
  - parameter  completion:  Closure that will be called for download associated when the request is completed.
  :result: Returns the FileDownload object that encapsulates the task underneath.
  */

  func download( url :String, resumeImmediately:Bool, _ completion:DownLoadCompletionHandler )-> FileDownload{

    //This internally creates the download task needed.
    let download : FileDownload =  FileDownload(session: session, url: url, resumesImmediately:resumeImmediately){
      [unowned self](url, filePath, success, error) in

      completion(url: url, filePath: filePath, success: success, error: error)

      //The download instance for this url should no longer be around, release it.
      self.activeDownloadsDict.removeValueForKey(url)
    }

    //Keep the download object around, until the callback is called.
    activeDownloadsDict[url] = download
    
    return download
  }
  
}
