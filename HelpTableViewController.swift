//
//  HelpTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import WebBrowser
//import ZendeskSDK

class HelpTableViewController: UITableViewController, WebBrowserDelegate {
    let helpArticles = ["Crypto 101"]
    let supportLinks = ["O3 Community", "Contact Us"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerView")
        let label = cell!.viewWithTag(1) as! UILabel
        if section == 0 {
            label.text = "Help guides"
        } else {
            label.text = "Get support"
        }
        label.theme_textColor = O3Theme.titleColorPicker
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "helpItemTableViewCell") as! HelpItemTableViewCell
        
        if indexPath.section == 0 {
            cell.data = helpArticles[indexPath.row]
        } else {
            cell.data = supportLinks[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            Controller().openDappBrowserV2(url: URL(string: "https://docs.o3.network/docs/privateKeysAddressesAndSignatures/")!)
        } else {
            if indexPath.row == 0 {
                openCommunityForum()
            } else {
                openHelpDesk()
            }
        }
    }
    
    func openCommunityForum() {
        let webBrowserViewController = WebBrowserViewController()
         
         webBrowserViewController.delegate = self
         webBrowserViewController.isToolbarHidden = true
         webBrowserViewController.title = ""
         webBrowserViewController.isShowURLInNavigationBarWhenLoading = false
         webBrowserViewController.barTintColor = UserDefaultsManager.theme.backgroundColor
         webBrowserViewController.tintColor = Theme.light.primaryColor
         webBrowserViewController.isShowPageTitleInNavigationBar = false
         webBrowserViewController.loadURLString("https://community.o3.network")
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
         self.navigationController?.pushViewController(webBrowserViewController, animated: true)
         }
    }
    
    func openHelpDesk() {
//        let config = RequestUiConfiguration()
//        config.subject = "iOS Support"
//        config.tags = [UIDevice.current.modelName, UIDevice.current.systemVersion,
//                       Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String ]
//        let viewController = RequestUi.buildRequestUi(with: [config])
//        self.navigationController?.pushViewController(viewController, animated: true)
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
