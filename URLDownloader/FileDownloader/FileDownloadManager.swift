//
//  FileDownloadManager.swift
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

public class FileDownloadManager {

  public typealias DownLoadCompletionHandler = (filePath: String?, success: Bool, error: NSError?)-> Void

  static let sharedInstance : FileDownloadManager = {
    var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    return FileDownloadManager(configuration: sessionConfig)
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

  //We want to store the last-modified date of a request, and also, the cache file path, where the pdf file is stored. The cache gets created within the default caches folder, so we dont need to really worry
  //about explicitely removing expired objects, or set expiry for cached objects. iOS will purge cache if need arises.
  public let cache = Cache<NSDictionary>(name: "DownloaderCache")

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