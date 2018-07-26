//
//  InboxItemTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/25/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import WebBrowser

class InboxItemTableViewCell: UITableViewCell {

    var inboxItem: InboxItem? {
        didSet {
            setupView()
        }
    }

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var readMoreButton: UIButton!
    @IBOutlet var actionButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupView () {
        iconImageView.kf.setImage(with: URL(string: inboxItem?.iconURL ?? ""))
        titleLabel.text = inboxItem?.title
        descriptionLabel.text = inboxItem?.description

        readMoreButton.setTitle(inboxItem?.readmoreTitle, for: .normal)
        actionButton.setTitle(inboxItem?.actionTitle, for: .normal)
    }

    @IBAction func readMoreTapped(_ sender: Any) {
        if inboxItem?.readmoreURL == nil {
            return
        }
        let webBrowserViewController = WebBrowserViewController()
        webBrowserViewController.tintColor = UserDefaultsManager.theme.titleTextColor
        webBrowserViewController.barTintColor = UserDefaultsManager.theme.backgroundColor
        webBrowserViewController.loadURL(URL(string: inboxItem!.readmoreURL)!)
        let navigationWebBrowser = WebBrowserViewController.rootNavigationWebBrowser(webBrowser: webBrowserViewController)
        UIApplication.appDelegate.window?.rootViewController?.present(navigationWebBrowser, animated: true, completion: nil)
    }

    @IBAction func actionTapped(_ sender: Any) {

        if inboxItem?.actionURL == nil {
            return
        }

        //the actionURL can be the deeplink inside the app too so we must validate it first
        let url = URL(string: inboxItem!.actionURL)
        if url?.scheme == "neo" {
            Router.parseNEP9URL(url: url!)
            return
        }
    }
}
