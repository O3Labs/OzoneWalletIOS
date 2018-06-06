//
//  BackupTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class BackupTableViewController: UITableViewController, HalfModalPresentable {
    @IBOutlet weak var emailBackupCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            maximizeToFullScreen()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.performSegue(withIdentifier: "segueToEmailBackup", sender: nil)
            }
        }
    }
}
