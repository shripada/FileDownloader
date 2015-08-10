//
//  ViewController.swift
//  URLDownloader
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  var download: FileDownload?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func download(sender: UIButton) {
    //Let us try to download this file
    //http://kmmc.in/wp-content/uploads/2014/01/lesson2.pdf
    let url = "http://kmmc.in/wp-content/uploads/2014/01/lesson2.pdf"

     sender.titleLabel?.enabled = false

      download = FileDownloadManager.sharedInstance.download(url){ (filePath, success, error) -> Void in
        if(success)
        {
            print("File downloaded at: \(filePath)")
        }
       sender.titleLabel?.enabled = true
    }

    //You can cancel the download if you want-
    //download.cancel()
  }

}

