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

  /**
    Designated Initializer
  */
  required public init(session: NSURLSession, url:String, _ completion: DownloadManager.DownLoadCompletionHandler )
  {
    self.session = session

    var shouldFetchFromServer = true

    var lastModifiedDate: String? = nil

    var cachedFilePath : String? = nil

    //Check if there is a cached response for this request
    if let cachedEntry:NSDictionary = DownloadManager.sharedInstance.cache.objectForKey(url){
        //Get the Last-Modified value
        lastModifiedDate = cachedEntry["lastModified"] as? String
        cachedFilePath = cachedEntry["cachedFilePath"] as? String
    }


      //We shall now make a head call to server, to check if the file is modified there.
      let request = NSMutableURLRequest(URL: NSURL(string:url)!)
      request.HTTPMethod = "HEAD"

       if let lastModifiedDate = lastModifiedDate{
        request.setValue(lastModifiedDate, forHTTPHeaderField: "If-Modified-Since");
       }

      session.dataTaskWithRequest(request){ [unowned self](data: NSData?, response:NSURLResponse!, error:NSError?) -> Void in
        let  status = (response  as! NSHTTPURLResponse).statusCode
        if(status == 304){ //Has not changed at server
            shouldFetchFromServer = false
        }

        if(shouldFetchFromServer){ //Probably the resource at server has changed.
          self.task = session.downloadTaskWithURL(NSURL(string:url)!){ (loc :NSURL!, response:NSURLResponse!, error:NSError!) -> Void in

            if(error == nil ){
              let httpResponse = response  as! NSHTTPURLResponse
              let  status = httpResponse.statusCode
              if(status == 200){
                //Successfully downloaded the file, let us move it to a safe place in caches folder.
                //TODO: We need to parameterise this as to where the file needs to be really
                //written
                let lastModifiedDate: String? = httpResponse.allHeaderFields["Last-Modified"] as? String
                var filePath = DownloadManager.sharedInstance.cacheDirectory;
                filePath = filePath.stringByAppendingPathComponent(url.lastPathComponent);
                //Delete the file at this location if exists.
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil)
                NSFileManager.defaultManager().moveItemAtURL(loc, toURL:NSURL(fileURLWithPath: filePath)!, error: nil)
                //Update this entry in the cache
                DownloadManager.sharedInstance.cache.setObject(["lastModified": lastModifiedDate!, "cachedFilePath":filePath], forKey: url)

                dispatch_sync(dispatch_get_main_queue())
                  {
                    completion(filePath:filePath, success: true, error: error)
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
                  completion(filePath: cachedFilePath, success: false, error: error)
              }

            }

          }
          
          self.task!.resume()
          
        }else{ //We have a valid cached file and nothing has changed in server, so return cached file path itself.
          dispatch_sync(dispatch_get_main_queue())
            {
              //Return cached file path itself, in case of failure.
              completion(filePath: cachedFilePath, success: true, error: nil)
          }
        }

      }.resume()


    }


  //Cancel the download
  func cancel(){
    self.task!.cancel()
  }



}