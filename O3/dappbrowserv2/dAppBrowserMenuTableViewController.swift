//
//  dAppBrowserMenuTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 12/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


class dAppBrowserMenuTableViewController: UITableViewController {

    var onRefresh: (()->())!
    var onClose: (()->())!
    var onShare: (()->())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            onRefresh()
        } else if indexPath.row == 1 {
            onShare()
        } else if indexPath.row == 2 {
            onClose()
        
        }
         self.dismiss(animated: true, completion: nil)
    }
}
