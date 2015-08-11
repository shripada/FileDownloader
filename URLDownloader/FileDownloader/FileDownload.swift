//
//  FileDownload.swift
//  URLDownloader
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import Foundation

/**
This encapsulates a download task for a given url.
This object will also ensure mechanisms to help resume a failed download.
Caller can use this also to cancel the download for any reason.
*/

public class FileDownload
{

  let session : NSURLSession!

  var task: NSURLSessionDownloadTask? = nil

  var url : String

  //MARK: 

  /**
  Designated Initializer
  Intiates a task to figure out if the file has changed at server, and if so, sets up a download task
  to fetch the file afresh. On the other hand, if the file is in cache, and not changed in server, just returns that.

  */
  required public init(session: NSURLSession, url:String, _ completion: FileDownloadManager.DownLoadCompletionHandler )
  {
    self.session = session
    self.url = url

    var shouldFetchFromServer = false

    var cachedFilePath : String? = nil

    //Check if there is a cached response for this request
    if let cachedEntry:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(url){
      //Check additionally that the file exists at the said path, iOS might have purged it in crunch
      //situations, if this file is missing, then we need to fetch the file from server.
      if let cachedFileName = cachedEntry["fileName"] as? String {
        cachedFilePath = FileDownloadManager.sharedInstance.cacheDirectory.stringByAppendingPathComponent(cachedFileName);
        if(!NSFileManager.defaultManager().fileExistsAtPath(cachedFilePath! )){
          shouldFetchFromServer = true
        }
      }
    }
    else{
      shouldFetchFromServer = true
    }

    if shouldFetchFromServer{
      download(completion)
    }else{
      downloadFromServerIfModified(completion)
    }

  }


  //Cancel the download
  func cancel(){
    self.task?.cancel()
  }

  //MARK: Internal funtions

  func downloadFromServerIfModified(completion: FileDownloadManager.DownLoadCompletionHandler)
  {

    var lastModifiedDate: String?
    var eTag: String?
    var filePath: String?

    //Check if there is a cached response for this request
    if let cachedEntry:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(url){
      //Get the Last-Modified value
      lastModifiedDate = cachedEntry["lastModified"] as? String
      eTag = cachedEntry["ETag"] as? String
      var fileName = cachedEntry["fileName"] as? String
      if let fileName = fileName {
        filePath = FileDownloadManager.sharedInstance.cacheDirectory.stringByAppendingPathComponent(fileName);
      }

    }


    //We shall now make a head call to server, to check if the file is modified there.
    let request = NSMutableURLRequest(URL: NSURL(string:self.url)!)
    request.HTTPMethod = "HEAD"

    if let lastModifiedDate = lastModifiedDate{
      request.setValue(lastModifiedDate, forHTTPHeaderField: "If-Modified-Since");
    }

    if let eTag = eTag{
      request.setValue(eTag, forHTTPHeaderField: "If-None-Match");
    }

    var shouldFetchFromServer = true

    session.dataTaskWithRequest(request){ [unowned self](data: NSData?, response:NSURLResponse!, error:NSError?) -> Void in
      let  status = (response  as! NSHTTPURLResponse).statusCode
      if(status == 304){ //Has not changed at server
        shouldFetchFromServer = false
      }else if(status == 200) //Changed at server
      {
        shouldFetchFromServer = true
      }

      if(shouldFetchFromServer){ //The resource at server has changed, fetch the latest
        self.download(completion)
      }
      else{ //Return the cached response
        if let filePath = filePath {
          dispatch_sync(dispatch_get_main_queue())
            {
              completion(filePath:filePath, success: true, error: nil)
          }
        }
      }
      }.resume()
  }

  func download(completion:FileDownloadManager.DownLoadCompletionHandler)->Void {
    self.task = session.downloadTaskWithURL(NSURL(string:url)!){ (loc :NSURL!, response:NSURLResponse!, error:NSError!) -> Void in

      if(error == nil ){
        let httpResponse = response  as! NSHTTPURLResponse
        let  status = httpResponse.statusCode

        if(status == 200){
          //Successfully downloaded the file, let us move it to a safe place in caches folder.
          let lastModifiedDate: String? = httpResponse.allHeaderFields["Last-Modified"] as? String
          let eTag : String? = httpResponse.allHeaderFields["ETag"] as? String
          var filePath = FileDownloadManager.sharedInstance.cacheDirectory;
          filePath = filePath.stringByAppendingPathComponent(self.url.lastPathComponent);
          //Delete the file at this location if exists before trying to move the downloaded content there.
          var error : NSError?

          if(NSFileManager.defaultManager().fileExistsAtPath(filePath)){
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
          }
          let success  = NSFileManager.defaultManager().moveItemAtURL(loc, toURL:NSURL(fileURLWithPath: filePath)!, error: &error)

          //Update this entry in the cache only if we were able to move the file successfully.
          if(error == nil){
            var cachedDict : [String:String] = ["fileName":filePath.lastPathComponent]

            if let lastModifiedDate = lastModifiedDate{
              cachedDict["lastModified"] = lastModifiedDate
            }
            if let eTag = eTag{
              cachedDict["ETag"] = eTag
            }

            FileDownloadManager.sharedInstance.cache.setObject(cachedDict, forKey: self.url)

          }

          dispatch_sync(dispatch_get_main_queue())
            {
              completion(filePath:filePath, success: success, error: error)
          }
        }
      }else{
        // Could it be a n/w failure, and if there is already some data downloaded, we want to resume from there
        // Check if the error' userInfo dict has resumeData
        // TODO: Need to handle resume of a failed request.
        // let resumeData : NSData? = error?.userInfo?[NSURLSessionDownloadTaskResumeData] as? NSData?
        dispatch_sync(dispatch_get_main_queue())
          {
            //Return cached file path itself, in case of failure.
            if let cachedEntry:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(self.url){
              if let fileName = cachedEntry["fileName"] as? String{
                var filePath = FileDownloadManager.sharedInstance.cacheDirectory;
                filePath = filePath.stringByAppendingPathComponent(fileName)
                completion(filePath: filePath, success: false, error: error)
              }
            }else{
              completion(filePath: nil, success: false, error: error)
            }

            
        }
        
      }
      
    }
    self.task?.resume()
  }
}
