//
//  DownloadCell.swift
//  FileDownloader
//
//  Created by Shripada Hebbar on 14/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import UIKit

class DownloadCell: UITableViewCell {

  @IBOutlet weak var urlField: UILabel!

  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

  @IBOutlet weak var startButton: UIButton!

  @IBOutlet weak var cancelButton: UIButton!

  @IBOutlet weak var tickMark: UIImageView!

  var download:FileDownload? {
    didSet{

      if(download != nil){
        activityIndicator.hidden = (download!.task!.state == NSURLSessionTaskState.Completed)
        tickMark.hidden = (download!.task!.state != NSURLSessionTaskState.Completed)
        urlField.text = download!.url

        if(download!.task!.state == NSURLSessionTaskState.Running){
          activityIndicator.hidden = false
          activityIndicator.startAnimating()
          startButton.enabled = false
          cancelButton.enabled = true
        }
        else{
          startButton.enabled = true
          cancelButton.enabled = false
        }
      }

    }
  }

  @IBAction func startDownload(sender: AnyObject) {
  if(download?.task?.state == NSURLSessionTaskState.Suspended){
  download?.resume()
    }else{
    //we need to start off a new download altogether.
    download?.download(downloadCallback)
    download?.resume()
    }
    startButton.enabled = false
    cancelButton.enabled = true
    activityIndicator.hidden = false
    activityIndicator.startAnimating()
    tickMark.hidden = true
  }

  @IBAction func cancelDownload(sender: AnyObject) {
    download?.cancel()
    startButton.enabled = true
    cancelButton.enabled = false
    activityIndicator.hidden = true
    tickMark.hidden = true

  }

func downloadCallback(url:String, filePath: String?, success: Bool, error: NSError?){
  if(success)
  {
    self.activityIndicator.hidden = true
    self.tickMark.hidden = false
    self.startButton.enabled  = true
    self.cancelButton.enabled = false
  }
}

 }
