//
//  PaperBackupConfirmTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/7/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Neoutils
import Channel
import KeychainAccess
import SwiftTheme
import PKHUD
import Crashlytics

class PaperBackupConfirmTableViewController: UITableViewController, UITextViewDelegate {
    @IBOutlet weak var paperBackupInfoOneLabel: UILabel!
    @IBOutlet weak var paperBackupInfoTwoLabel: UILabel!
    @IBOutlet weak var wifTextView: O3TextView!

    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar(frame: CGRect.zero)
        toolbar.barStyle = .default
        toolbar.sizeToFit()
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: Theme.light.primaryColor,
                                                        NSAttributedStringKey.font: UIFont(name: "Avenir-Medium", size: 17)!]
        let disabledAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: Theme.light.disabledColor,
                                                        NSAttributedStringKey.font: UIFont(name: "Avenir-Medium", size: 17)!]
        doneButton.setTitleTextAttributes(attributes, for: UIControlState.normal)
        doneButton.setTitleTextAttributes(disabledAttributes, for: UIControlState.disabled)
        toolbar.setItems([flexibleButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true

        return toolbar
    }()

    var wif = ""
    var doneButton = UIBarButtonItem(title: OnboardingStrings.continueButton, style: .plain, target: self,
                                     action: #selector(continueButtonTapped(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        wifTextView.delegate = self
        wifTextView.becomeFirstResponder()
        wifTextView.inputAccessoryView = inputToolbar

        doneButton.isEnabled = false
    }

    func setLocalizedStrings() {
        self.title = OnboardingStrings.enterPrivateKey
        paperBackupInfoOneLabel.text = OnboardingStrings.paperBackupInfoOne
        paperBackupInfoTwoLabel.text = OnboardingStrings.paperBackupInfoTwo
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            doneButton.isEnabled = false
        } else {
            doneButton.isEnabled = true
        }
    }

    func loginToApp() {
        guard let account = Account(wif: wif) else {
            return
        }
        let keychain = Keychain(service: "network.o3.neo.wallet")
        Authenticated.account = account
        Channel.pushNotificationEnabled(true)

        DispatchQueue.main.async {
            self.dismissKeyboard()
            HUD.show(.labeledProgress(title: nil, subtitle: OnboardingStrings.selectingBestNodeTitle))
        }

        DispatchQueue.global(qos: .background).async {
            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                AppState.bestSeedNodeURL = bestNode
            }
            DispatchQueue.main.async {
                HUD.hide()
                do {
                    //save pirivate key to keychain
                    try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .set(account.wif, key: "ozonePrivateKey")
                    SwiftTheme.ThemeManager.setTheme(index: UserDefaultsManager.themeIndex)
                    self.instantiateMainAsNewRoot()
                } catch _ {
                    return
                }
            }
        }
    }

    func instantiateMainAsNewRoot() {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }

    @objc func continueButtonTapped(_ sender: Any?) {
        if wifTextView.text.trim() == wif {
            Answers.logCustomEvent(withName: "Paper Backup Completed", customAttributes: [:])
            loginToApp()
        } else {
            DispatchQueue.main.async {
                OzoneAlert.alertDialog(message: OnboardingStrings.notMatchedWif, dismissTitle: OzoneAlert.confirmPositiveConfirmString) {
                }
            }
        }
    }
}
