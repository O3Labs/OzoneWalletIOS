//
//  InboxTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InboxTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavBarTheme()
        setThemedElements()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .plain, target: self, action: #selector(dismissTapped))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "cog"), style: .plain, target: self, action: #selector(showSettingsMenu))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inbox-cell") as? InboxTableViewCell else {
            fatalError("Unrecoverable error occurred")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    @objc func showSettingsMenu() {
        
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
