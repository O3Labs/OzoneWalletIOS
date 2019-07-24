//
//  SortTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 7/23/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class SortTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setThemedElements()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sortOptionCell")!
        let label = cell.viewWithTag(1) as! UILabel
        let imageView = cell.viewWithTag(2) as! UIImageView
        if indexPath.row == 0 {
            label.text = "Default"
            imageView.isHidden = !(UserDefaultsManager.portfolioSortType == .defaultSort)
        } else if indexPath.row == 1 {
            label.text = "A to Z"
            imageView.isHidden = !(UserDefaultsManager.portfolioSortType == .atozSort)
        } else {
            label.text = "Most Value"
            imageView.isHidden = !(UserDefaultsManager.portfolioSortType == .valueSort)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            UserDefaultsManager.portfolioSortType = .defaultSort
        } else if indexPath.row == 1 {
            UserDefaultsManager.portfolioSortType = .atozSort
        } else {
            UserDefaultsManager.portfolioSortType = .valueSort
        }
        NotificationCenter.default.post(name: Notification.Name("NEP6Updated"), object: nil)
        self.dismissTapped()
    }
    
    func setThemedElements() {
        applyBottomSheetNavBarTheme(title: "Sort Portfolio")
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
