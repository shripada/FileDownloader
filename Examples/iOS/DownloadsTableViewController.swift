//
//  DownloadsTableViewController.swift
//  FileDownloader
//
//  Created by Shripada Hebbar on 14/08/15.
//  Copyright (c) 2015 Shripada Hebbar. All rights reserved.
//

import UIKit

class DownloadsTableViewController: UITableViewController {

  let filesTobeDownloaded = [
    "https://upload.wikimedia.org/wikipedia/commons/9/95/Tracy_Caldwell_Dyson_in_Cupola_ISS.jpg",
    "http://www.mfiles.co.uk/mp3-downloads/frederic-chopin-piano-sonata-2-op35-3-funeral-march.mp3",
    "http://edmullen.net/test/rc.jpg",
    "http://kmmc.in/wp-content/uploads/2014/01/lesson2.pdf",
    "http://fzs.sve-mo.ba/sites/default/files/dokumenti-vijesti/sample.pdf"
  ]

  override func viewDidLoad() {
        super.viewDidLoad()
    tableView.reloadData()
  }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesTobeDownloaded.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell:DownloadCell = tableView.dequeueReusableCellWithIdentifier("DownloadCell", forIndexPath: indexPath) as! DownloadCell

      //check if cell already has a download object with it, if so, we need to cancel and clear it.
      if cell.download != nil {
        cell.download?.cancel()
        cell.download = nil
      }

      //Create the appropriate download cell
      cell.download  = FileDownloadManager.sharedInstance.download(filesTobeDownloaded[indexPath.row], resumeImmediately: false, cell.downloadCallback)
        return cell
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
