# FileDownloader
Many a times, we will be required to download a huge pdf file, or a mp4 file, etc. It is very important to have a mechanism to cache 
these, otherwise lot of n/w bandwidth will be wasted while trying to fetch them each time. Generally servers do not enable http level
caching for this kind of files, and instead prefer the **ETag** and **Last-Modified** fields in the http response headers. However, there is no protocol level support to automatically support caching with these fields.  A brief explanation of these fields:


* Last-Modified - The value of this header corresponds to the date and time when the requested resource was last changed. For example, if a client requests a timeline of recent photos, /photos/timeline, the Last-Modified value could be set to when the most recent photo was taken.
* Etag - An abbreviation for "entity tag", this is an identifier that represents the contents requested resource. In practice, an Etag header value could be something like the MD5 digest of the resource properties. This is particularly useful for dynamically generated resources that may not have an obvious Last-Modified value.

The FileDownloadManager class is a singleton and it allows you to initite a download and handle caching automatically for you.
