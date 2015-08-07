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

  let session : NSURLSession

  let task: NSURLSessionDownloadTask

  /**
    Designated Initializer
  */
  required public init(session: NSURLSession, url:String, _ completion: DownloadManager.DownLoadCompletionHandler )
  {
    self.session = session

    self.task = session.downloadTaskWithURL(NSURL(string: url)!){ (loc :NSURL!, response:NSURLResponse!, error:NSError!) -> Void in

      if(error == nil ){
          let  status = (response  as! NSHTTPURLResponse).statusCode
          if(status == 200){
            //Successfully downloaded the file, let us move it to a safe place in caches folder.
            //TODO: We need to parameterise this as to where the file needs to be really
            //written
            var filePath = DownloadManager.sharedInstance.cacheDirectory;
            filePath = filePath.stringByAppendingPathComponent(url.lastPathComponent);
            NSFileManager.defaultManager().moveItemAtURL(loc, toURL:NSURL(fileURLWithPath: filePath)!, error: nil)
           completion(filePath:filePath, success: true, error: error)
        }
      }
      else
      {
        // Could it be a n/w failure, and if there is already some data downloaded, we want to resume from there
        // Check if the error' userInfo dict has resumeData
        // TODO: Need to handle resume of a failed request.
        // let resumeData : NSData? = error?.userInfo?[NSURLSessionDownloadTaskResumeData] as? NSData?
        completion(filePath: nil, success: false, error: error)
      }

    }

    self.task.resume()

  }

  //Cancel the download
  func cancel(){
    self.task.cancel()
  }



}