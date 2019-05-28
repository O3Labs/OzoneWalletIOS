//
//  InboxTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class InboxTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate,
    NotificationDelegate {
    var dummyMessages = [Message]()
    
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaultsManager.needsInboxBadge = false
        applyNavBarTheme()
        setThemedElements()
        setLocalizedStrings()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close-x"), style: .plain, target: self, action: #selector(dismissTapped))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "cog"), style: .plain, target: self, action: #selector(showSettingsMenu(_:)))
        
        if UserDefaultsManager.hasAgreedInbox == false {
            displayOptInBottomSheet()
        } else {
            loadMessages()
        }
        
        UserDefaultsManager.lastInboxOpen = Int(Date().timeIntervalSince1970)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    func displayOptInBottomSheet() {
        let nav = UIStoryboard(name: "Disclaimers", bundle: nil).instantiateViewController(withIdentifier: "inboxDisclaimerNav") as! UINavigationController
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        (nav.children.first as! InboxDisclaimerViewController).delegate = self
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numMessages = dummyMessages.count
        if numMessages == 0 {
            tableView.setEmptyMessage("You currently have no inbox items")
        } else {
            tableView.restore()
        }
        return numMessages
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inbox-cell") as? InboxTableViewCell else {
                fatalError("Unrecoverable error occurred")
        }
            
        cell.data = dummyMessages[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = dummyMessages[indexPath.row].action else {
            return
        }
        if action.type == "browser" {
            if action.url.starts(with: "o3network") {
                self.dismiss(animated: true)
                Router.parseO3NetworkScheme(url: URL(string: action.url)!)
            } else {
                Controller().openDappBrowserV2(url: URL(string: action.url)!)
            }
        }
    }
    
    func loadMessages() {
        let pubkey = O3KeychainManager.getO3PubKey()!
        O3APIClient(network: AppState.network).getMessages(pubKey: pubkey) { result in
            switch result {
            case .failure(_) :
                return
            case .success(let messages):
                self.dummyMessages = messages
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
        }
    }
    
    
    @objc func showSettingsMenu(_ sender: UIBarButtonItem) {
        let vc = UIStoryboard(name: "Inbox", bundle: nil).instantiateViewController(withIdentifier: "InboxSettingsMenuTableViewController") as! InboxSettingsMenuTableViewController
        vc.delegate = self
        //number of menus x cell height
        let height = CGFloat(4 * 60.0)
        vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: height)
        vc.modalPresentationStyle = .popover
        let presentationController = vc.presentationController as! UIPopoverPresentationController
        presentationController.theme_backgroundColor = O3Theme.backgroundColorPicker
        presentationController.barButtonItem = sender
        presentationController.delegate = self
        presentationController.sourceRect = CGRect(x: 0, y: 0, width: 25, height: 25)
        presentationController.permittedArrowDirections = [.any]
        
        self.present(vc, animated: true)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle{
        return .none
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
    }
    
    func setLocalizedStrings() {
        navigationItem.title = "Inbox"
    }
}
