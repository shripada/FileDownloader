//
//  FileDownload.swift
//  Version 1.0.1
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import Foundation

/**
 This encapsulates a download task for a given url.
 Fecilitates an immediate or a future download.  If you dont want an immediate download, you need to keep a reference to this
 object and explicitely initiate the download using the 'resume' method. A download can be terminated by 'cancel' method.
 */

public class FileDownload
{
    
    let session : NSURLSession!
    
    var task: NSURLSessionDownloadTask? = nil
    
    var headRequestTask: NSURLSessionDataTask? = nil
    
    var url : String
    
    var resumesImmediately:Bool = true
    
    var cachedFilePath: String? {
        get{
            if let cacheEntry = cacheEntry(),
                fileName = cacheEntry["fileName"]{
                return (FileDownloadManager.cacheDirectory as NSString).stringByAppendingPathComponent(fileName)
                
            }
            return nil
        }
    }
    
    
    //MARK:
    
    /**
     Designated Initializer. Sets up the object and initiates a download
     - parameter  session: - Reference to the session in which the download task to be created.
     - parameter  url: - The url to which a GET is requested via a download task
     - parameter  resumesImmediately:: A bool, true if the download should begin immediately, false otherwise.
     - parameter  completion: - The closure to be called once the donwload is completed, or failed with an error.
     
     - returns:  The FileDownload object. client should keep a reference to it, in case they want to resume/cancel the download.
     */
    
    required public init(session: NSURLSession, url:String, resumesImmediately:Bool, _ completion: FileDownloadManager.DownLoadCompletionHandler )
    {
        self.session = session
        self.url = url
        self.resumesImmediately = resumesImmediately
        
        download(completion)
    }
    
    /**
     Convinience initializer.
     Use this if you want to iniite a download immediately.
     - parameter  session: - Reference to the session in which the download task to be created.
     - parameter  url: - The url to which a GET is requested via a download task
     - parameter  completion: - The closure to be called once the donwload is completed, or failed with an error.
     
     - returns:  The FileDownload object. client should keep a reference to it, in case they want to cancel the download.
     */
    convenience public init(session: NSURLSession, url:String, _ completion: FileDownloadManager.DownLoadCompletionHandler )
    {
        self.init(session:session, url:url, resumesImmediately:true, completion)
    }
    
    /**
     Use this to cancel the download.
     */
    func cancel(){
        self.task?.cancel()
    }
    
    /**
     Starts a suspended download.
     */
    func resume(){
        self.task?.resume()
    }
    
    /**
     Suspends a download temporarily.
     */
    func suspend(){
        self.task?.suspend()
    }
    
    /**
     Manages the creation of the download task, and ensures caching the response, by making use of the
     ETag, and Last-Modified response headers. Caches the ETag, and Last-Modified values of a successfull response.
     In the subsequent calls it prepares the 'If-Modified-Since', and 'If-None-Match' request headers. Server will
     only send back actual response data, if the resources are modified, otherwise it returns with a response code
     of 304 and this method simply returns the cached file in the completion handler. If server sees the resource
     is modified, we get response with 204, and we will cache the file in that case along with new ETag, and
     Last-Modified' headers. If a task is in progress, it cancels it first, before creating a new one.
     
     - parameter completion:  - The completion handler to be called.
     
     */
    func download(completion:FileDownloadManager.DownLoadCompletionHandler)->Void {
        
        //Cancel if a task exists already
        self.task?.cancel()
        
        var lastModifiedDate: String?
        var eTag: String?
        var filePath: String?
        
        let request = NSMutableURLRequest(URL: NSURL(string:self.url)!)
        
        //Check if there is a cached response for this request, then we need to prepare request headers
        //provided the cached file exists, otherwise no need of the cache headers as in this case we need
        //to pull fresh data.
        if let entry:[String:String] = self.cacheEntry(),
            let filePathTemp = entry["filePath"]{
            //Remove the cache entry altogether, if there is no cached file present.
            if !NSFileManager.defaultManager().fileExistsAtPath(filePathTemp){
                FileDownloadManager.sharedInstance.cache.removeObjectForKey(self.url)
            }else{
                //record the cached header values.
                lastModifiedDate = entry["lastModified"]
                eTag = entry["ETag"]
                filePath = filePathTemp
            }
        }
        
        //Setup the cache headers
        if let lastModifiedDate = lastModifiedDate{
            request.setValue(lastModifiedDate, forHTTPHeaderField: "If-Modified-Since");
        }
        
        if let eTag = eTag{
            request.setValue(eTag, forHTTPHeaderField: "If-None-Match");
        }
        
        //Create the download task
        self.task = session.downloadTaskWithRequest(request){ (loc :NSURL?, response:NSURLResponse?, error:NSError?) -> Void in
            
            if(error == nil ){
                let httpResponse = response  as! NSHTTPURLResponse
                let  status = httpResponse.statusCode
                
                if(status == 304){//Not modified at server
                    //Return cached file path
                    dispatch_sync(dispatch_get_main_queue()){
                        completion(url:self.url, filePath: filePath, success: true, error: error)
                    }
                }else if(status == 200){
                    //Successfully downloaded the file, extract ETag amd Last-Modified
                    let lastModifiedDate: String? = httpResponse.allHeaderFields["Last-Modified"] as? String
                    let eTag : String? = httpResponse.allHeaderFields["ETag"] as? String
                    
                    //Re-use same file path if present, otherwise compute it.
                    if (filePath == nil){
                        filePath = FileDownloadManager.cacheDirectory;
                        //Ensure a unique file name to avoid conflicts
                        filePath = (filePath! as NSString).stringByAppendingPathComponent(NSUUID().UUIDString + "-" + (self.url as NSString).lastPathComponent );
                    }
                    
                    //Remove the file at this path if already present before we move the new one
                    if(NSFileManager.defaultManager().fileExistsAtPath(filePath!)){
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(filePath!)
                        } catch _ {
                        }
                    }
                    
                    var error : NSError? = nil
                    let success: Bool
                    do {
                        try NSFileManager.defaultManager().moveItemAtURL(loc!, toURL:NSURL(fileURLWithPath: filePath!))
                        success = true
                    } catch  let error1 as NSError {
                        error = error1
                        success = false
                    } catch {
                        fatalError()
                    }
                    
                    //Update this entry in the cache only if we were able to move the file successfully.
                    if(error == nil){
                        let lastComponent = (filePath! as NSString).lastPathComponent
                        var cachedDict : [String:String] = ["fileName":lastComponent]
                        
                        if let lastModifiedDate = lastModifiedDate{
                            cachedDict["lastModified"] = lastModifiedDate
                        }
                        if let eTag = eTag{
                            cachedDict["ETag"] = eTag
                        }
                        //Cache the entry
                        FileDownloadManager.sharedInstance.cache.setObject(cachedDict, forKey: self.url)
                        
                    }
                    
                    dispatch_sync(dispatch_get_main_queue()){
                        completion(url: self.url, filePath:filePath, success: success, error: error)
                    }
                }
            }else{
                // Could it be a n/w failure, and if there is already some data downloaded, we want to resume from there
                // Check if the error' userInfo dict has resumeData
                // TODO: Need to handle resume of a failed request.
                // let resumeData : NSData? = error?.userInfo?[NSURLSessionDownloadTaskResumeData] as? NSData?
                dispatch_sync(dispatch_get_main_queue()){
                    //Return cached file path itself, in case of failure.
                    completion(url:self.url, filePath:filePath, success: false, error: error)
                }
            }
            
        }
        
        if(resumesImmediately){
            self.resume()
        }
    }
    
    //MARK: Internal funtions
    
    func cacheEntry() -> [String:String]?{
        if let cachedEntry:NSDictionary = FileDownloadManager.sharedInstance.cache.objectForKey(self.url){
            if let fileName = cachedEntry["fileName"] as? String{
                var filePath = FileDownloadManager.cacheDirectory;
                filePath = (filePath as NSString).stringByAppendingPathComponent(fileName)
                return ["filePath" : filePath, "lastModified": cachedEntry["lastModified"] as! String, "ETag" : cachedEntry["ETag"] as! String ]
                
            }
        }
        return nil
    }
    
}

