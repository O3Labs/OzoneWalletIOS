//
//  HelpTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class HelpTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerView")
        let label = cell!.viewWithTag(1) as! UILabel
        if section == 0 {
            label.text = "Help guides"
        } else {
            label.text = "Get support"
        }   
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return UITableViewCell()
        } else {
            return UITableViewCell()
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        title = "Help"
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
    }
}
