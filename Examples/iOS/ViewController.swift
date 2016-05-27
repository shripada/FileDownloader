//
//  ViewController.swift
//  URLDownloader
//
//  Created by Shripada Hebbar on 07/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // var downloadImmediately: FileDownload?
    // var downloadLater: FileDownload?
    
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
        
        FileDownloadManager.sharedInstance.download(url){ (url,filePath, success, error) -> Void in
            if(success)
            {
                print("File from \(url) \n downloaded at: \(filePath)", terminator: "")
            }
            sender.titleLabel?.enabled = true
        }
        
        
        let anotherURL = "http://fzs.sve-mo.ba/sites/default/files/dokumenti-vijesti/sample.pdf"
        
        let downloadLater = FileDownloadManager.sharedInstance.download(anotherURL, resumeImmediately:false){(url,filePath, success, error) -> Void in
            if(success)
            {
                print("File from \(url) \n downloaded at: \(filePath)", terminator: "")
            }
            sender.titleLabel?.enabled = true
        }
        
        //You need to explictely initiate download when you want
        downloadLater.resume()
    }
    
}

