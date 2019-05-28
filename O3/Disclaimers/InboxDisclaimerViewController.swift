//
//  InboxDisclaimerViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/24/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import M13Checkbox
import ActiveLabel

class InboxDisclaimerViewController: UIViewController {
    @IBOutlet weak var warningImageView: UIImageView!
    @IBOutlet weak var warningTitleLabel: UILabel!
    @IBOutlet weak var warningDescriptionLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton!
    
    @IBOutlet weak var checkboxContainer: UIView!
    @IBOutlet weak var checkboxDescription: UILabel!
    let checkbox = M13Checkbox(frame: CGRect(x: 0.0, y: 0.0, width: 24.0, height: 24.0))
    
    weak var delegate: NotificationDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        
        warningImageView.tintColor = Theme.light.primaryColor
        checkbox.checkState = .checked
        checkboxContainer.embed(checkbox)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismissTapped()
    }
    
    func subscribeToDefaultO3Topic() {
        UserDefaultsManager.subscribedServices = [UserDefaultsManager.Subscriptions.o3.rawValue]
        var group = DispatchGroup()
        DispatchQueue.global().async {
            group.enter()
            O3APIClient(network: AppState.network).subscribeToTopic(topic: UserDefaultsManager.Subscriptions.o3.rawValue) { result in
                group.leave()
                switch result {
                case .failure(_):
                    return
                case .success(_):
                    return
                }
            }
        }
        
        for account in NEP6.getFromFileSystem()?.accounts ?? [] {
            DispatchQueue.global().async {
                group.enter()
                O3APIClient(network: AppState.network).subscribeToTopic(topic: account.address) { result in
                    group.leave()
                    switch result {
                    case .failure(_):
                        return
                    case .success(_):
                        return
                    }
                }
            }
        }
        group.wait()
        delegate?.loadMessages()
    }
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        if (checkbox.checkState == .checked) {
            subscribeToDefaultO3Topic()
            UserDefaultsManager.hasAgreedInbox = true
        }
        self.dismissTapped()
    }
    
    func setLocalizedStrings() {
        warningTitleLabel.text = "Welcome to O3's Decentralized Inbox"
        warningDescriptionLabel.text = "O3's decentralized inbox allows you to get up to date information from O3 as well as various projects in the NEO ecosystem like Switcheo, NGD, and others. You can unsubscribe from update anytime"
        checkboxDescription.text = "Don't show this again"
        agreeButton.setTitle("Receive Inbox Messages", for: UIControl.State())
    }
    
    func setThemedElements() {
        warningTitleLabel.theme_textColor = O3Theme.titleColorPicker
        warningDescriptionLabel.theme_textColor = O3Theme.lightTextColorPicker
        checkboxDescription.theme_textColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}


