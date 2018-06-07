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

class NEP2PasswordConfirmViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showButton: UIButton!
    var wif = ""

    var previousPassword: String!

    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.sizeToFit()
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        var doneButton = UIBarButtonItem(title: OnboardingStrings.continueButton, style: .plain, target: self, action: #selector(self.continueButtonTapped(_:)))

        toolbar.setItems([flexibleButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true

        return toolbar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.inputAccessoryView = inputToolbar
        passwordField.becomeFirstResponder()
        setLocalizedStrings()
    }

    func validatePassword() -> Bool {
        if previousPassword == passwordField.text?.trim() {
            return true
        }
        return false
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        if validatePassword() {
            if !MFMailComposeViewController.canSendMail() {
                print("Mail services are not available")
                return
            }

            var error: NSError?
            let nep2 = NeoutilsNEP2Encrypt(wif, previousPassword, &error)
            let json = NeoutilsGenerateNEP6FromEncryptedKey("My O3 Wallet", "My O3 Address", nep2?.address(), nep2?.encryptedKey())

            let image = UIImage(qrData: "Andrei is Cool", width: 150, height: 150)
            let imageData = UIImagePNGRepresentation(image) ?? nil
            let base64String = imageData?.base64EncodedString() ?? "" // Your String Image
            let strHtml = "<html><body><p>Header: Hello Test Email</p><p><b><img src='data:image/png;base64,\(String(describing: base64String))' alt='Logo' title='Logo' style='display:block' width='150' height='150'></b></p></body></html>"
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.setToRecipients(["address@example.com"])
            composeVC.setSubject("Hello!")
            composeVC.setMessageBody(strHtml, isHTML: true)

            composeVC.addAttachmentData((json?.data(using: .utf8))!, mimeType: "application/json", fileName: "O3Wallet.json")
            composeVC.addAttachmentData(imageData!, mimeType: "image/png", fileName: "key.png")

            // Present the view controller modally.
            DispatchQueue.main.async {
                let transitionDelegate = DeckTransitioningDelegate()
                composeVC.transitioningDelegate = transitionDelegate
                composeVC.modalPresentationStyle = .custom
                self.present(composeVC, animated: true, completion: nil)
            }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
            if result == .cancelled || result == .failed {
                OzoneAlert.alertDialog(message: "fadadaf", dismissTitle: "fdsafda") {

                }
            } else {
                self.loginToApp()
            }
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
