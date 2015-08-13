# FileDownloader
Many a times, we will be required to download a huge pdf file, or a mp4 file, etc. It is very important to have a mechanism to cache 
these, otherwise lot of n/w bandwidth will be wasted while trying to fetch them each time. Generally servers do not enable http level
caching for this kind of files, and instead prefer the **ETag** and **Last-Modified** fields in the http response headers. However, there is no protocol level support to automatically support caching with these fields. 


A brief explanation of these response fields:


* Last-Modified - The value of this header corresponds to the date and time when the requested resource was last changed. For example, if a client requests a pdf file, the server can send the 'Last-modifiled' field as the time when the pdf document was last edited.
* Etag - An abbreviation for "entity tag", this is an identifier that represents the contents requested resource. In practice, an Etag header value could be something like the MD5 digest of the resource properties. This is particularly useful for dynamically generated resources that may not have an obvious Last-Modified value.

Client can cache these values and before issueing actual GET request next time, it can send these two values as two special fields in the request header in a HEAD call. The fields are:
* If-Modified-Since  - This field will have the cached value of Last-Modified value received from server response header.
* If-None-Match  - This field will have the cached value of 'ETag' field received from server response header.

Server will send a status 200 (OK) indicating, there is an updated content, and 304 (Not modified). Client needs to issue a fresh GET request in the former case, and just return cached file in the latter case.



The FileDownloadManager class is a singleton and it allows you to initite a download and handle caching automatically for you by using the ETag and Last-Modified fields for caching.

## FileDownloadManager Usage

• Download immediately-
```
  let url = "http://kmmc.in/wp-content/uploads/2014/01/lesson2.pdf"

     sender.titleLabel?.enabled = false

    let downloadImmediately = FileDownloadManager.sharedInstance.download(url){ [unowned self](url,filePath, success, error) -> Void in
        if(success)
        {
            print("File from \(url) \n downloaded at: \(filePath)")
        }
        
        

    }
```
• Download later:
```
    let anotherURL = "http://fzs.sve-mo.ba/sites/default/files/dokumenti-vijesti/sample.pdf"

     let downloadLater  = FileDownloadManager.sharedInstance.download(anotherURL, resumeImmediately:false){ [unowned self](url,filePath, success, error) -> Void in
      if(success)
      {
        print("File from \(url) \n downloaded at: \(filePath)")
      }
      
   
    }

    //You need to explictely initiate download when you want
    downloadLater.resume()
   ``` 

## Important notes
You should never hardcode or cache the file path returned by the callback, as the file downloader caches files in default cache folder and absolute references to this folder should never be stored.  Every time you want the file, it is advised to fetch the path via FileDownloadManager:download  only. 

