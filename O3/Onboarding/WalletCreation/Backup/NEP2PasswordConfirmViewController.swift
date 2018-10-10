//
//  NEP2PasswordConfirmViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import DeckTransition
import Neoutils
import Channel
import KeychainAccess
import SwiftTheme
import PKHUD
import Crashlytics

class NEP2PasswordConfirmViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showButton: UIButton!
    var wif = ""

    var previousPassword: String!

    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar(frame: CGRect.zero)
        toolbar.barStyle = .default
        toolbar.barTintColor = .white
        toolbar.sizeToFit()
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: Theme.light.primaryColor,
                                                         NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17)!]
        let disabledAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: Theme.light.disabledColor,
                                                                 NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17)!]
        doneButton.setTitleTextAttributes(attributes, for: UIControl.State.normal)
        doneButton.setTitleTextAttributes(disabledAttributes, for: UIControl.State.disabled)
        toolbar.setItems([flexibleButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true

        return toolbar
    }()

    var passwordIsSecure = true
    var doneButton = UIBarButtonItem(title: OnboardingStrings.continueButton, style: .plain, target: self, action: #selector(continueButtonTapped(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = false
        passwordField.inputAccessoryView = inputToolbar
        passwordField.setLeftPaddingPoints(CGFloat(10.0))
        passwordField.setRightPaddingPoints(CGFloat(10.0))
        passwordField.becomeFirstResponder()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        setLocalizedStrings()
    }

    func validatePassword() -> Bool {
        if previousPassword == passwordField.text?.trim() {
            return true
        }
        return false
    }

    @IBAction func textFieldChanged(_ sender: Any) {
        if passwordField.text == "" {
            doneButton.isEnabled = false
        } else {
            doneButton.isEnabled = true
        }
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        if validatePassword() {
            if !MFMailComposeViewController.canSendMail() {
                OzoneAlert.confirmDialog(OnboardingStrings.mailNotSetupTitle, message: OnboardingStrings.mailNotSetupMessage,
                                         cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.okPositiveConfirmString, didCancel: { return }) {
                        self.loginToApp()
                }
                return
            }

            var error: NSError?
            let nep2 = NeoutilsNEP2Encrypt(wif, previousPassword, &error)
            let json = NeoutilsGenerateNEP6FromEncryptedKey("My O3 Wallet", "My O3 Address", nep2?.address(), nep2?.encryptedKey())
            let nep2String = (nep2?.encryptedKey())!

            let image = UIImage(qrData: nep2String, width: 200, height: 200, qrLogoName: "ic_QRkey")
            let imageData = image.pngData() ?? nil
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.setSubject(OnboardingStrings.emailSubject)
            composeVC.setMessageBody(String.localizedStringWithFormat(String(OnboardingStrings.emailBody), nep2String), isHTML: false)

            composeVC.addAttachmentData((json?.data(using: .utf8))!, mimeType: "application/json", fileName: "O3Wallet.json")
            composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")

            // Present the view controller modally.
            DispatchQueue.main.async {
                let transitionDelegate = DeckTransitioningDelegate()
                composeVC.transitioningDelegate = transitionDelegate
                composeVC.modalPresentationStyle = .custom
                self.present(composeVC, animated: true, completion: nil)
            }
        } else {
            OzoneAlert.alertDialog(message: OnboardingStrings.passwordMismatch, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordField.text = ""
            }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            if result == .cancelled || result == .failed {
                OzoneAlert.alertDialog(message: OnboardingStrings.failedToSendEmailDescription, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                    return
                }
            } else {
                Answers.logCustomEvent(withName: "Email Backup Completed", customAttributes: [:])
                self.loginToApp()
            }
        }
    }

    @IBAction func showTapped(_ sender: Any) {
        passwordIsSecure = !passwordIsSecure
        passwordField.isSecureTextEntry = passwordIsSecure
        let tmp = passwordField.text
        passwordField.text = ""
        passwordField.text = tmp

        if passwordIsSecure {
            showButton.alpha = CGFloat(0.3)
        } else {
            showButton.alpha = CGFloat(1.0)
        }
    }

    func loginToApp() {
        dismissKeyboard()
        guard let account = Account(wif: wif) else {
            return
        }
        let keychain = Keychain(service: "network.o3.neo.wallet")
        Authenticated.account = account
        Channel.pushNotificationEnabled(true)

        DispatchQueue.main.async {
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

    func setLocalizedStrings() {
        title = OnboardingStrings.reenterPassword
        descriptionLabel.text = OnboardingStrings.reenterPasswordDescription
        passwordField.placeholder = OnboardingStrings.reenterPasswordHint
    }
}
