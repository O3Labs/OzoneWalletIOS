//
//  BackupTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import KeychainAccess
import PKHUD
import Channel
import SwiftTheme
import Crashlytics

class BackupTableViewController: UITableViewController, HalfModalPresentable {
    @IBOutlet weak var emailBackupCell: UITableViewCell!

    @IBOutlet weak var emailBackupLabel: UILabel!
    @IBOutlet weak var reccomendedLabel: UILabel!
    @IBOutlet weak var imageBackupLabel: UILabel!
    @IBOutlet weak var copyBackupLabel: UILabel!
    @IBOutlet weak var paperBackupLabel: UILabel!
    @IBOutlet weak var goBackLabel: UILabel!

    var wif = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        self.navigationController?.hideHairline()
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            maximizeToFullScreen(allowReverse: false)
            Answers.logCustomEvent(withName: "Backup Selected", customAttributes: ["Option": 0])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.performSegue(withIdentifier: "segueToEmailBackup", sender: nil)
            }
        }

        if indexPath.row == 1 {
            DispatchQueue.main.async {
                Answers.logCustomEvent(withName: "Backup Selected", customAttributes: ["Option": 1])
                OzoneAlert.confirmDialog(OnboardingStrings.screenShotTakenAlertTitle, message: OnboardingStrings.screenShotTakenAlertDescription, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                    self.loginToApp()
                }
            }

        } else if indexPath.row == 2 {
            DispatchQueue.main.async {
                Answers.logCustomEvent(withName: "Backup Selected", customAttributes: ["Option": 2])
                OzoneAlert.confirmDialog(OnboardingStrings.copiedToClipboardAlertTitle, message: OnboardingStrings.copiedToClipboardAlertDescription, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: OzoneAlert.confirmPositiveConfirmString, didCancel: {}) {
                    self.loginToApp()
                }
            }

        } else if indexPath.row == 3 {
            Answers.logCustomEvent(withName: "Backup Selected", customAttributes: ["Option": 3])
            maximizeToFullScreen(allowReverse: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.performSegue(withIdentifier: "segueToPaperBackup", sender: nil)
            }
        } else if indexPath.row == 4 {
            DispatchQueue.main.async { self.dismiss(animated: true, completion: nil) }
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? NEP2PasswordViewController {
            dest.wif = wif
        }
        if let dest = segue.destination as? PaperBackupConfirmTableViewController {
            dest.wif = wif
        }

    }
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func setLocalizedStrings() {
        title = OnboardingStrings.backup
        reccomendedLabel.text = OnboardingStrings.reccommended
        emailBackupLabel.text = OnboardingStrings.backupOptionEmail
        imageBackupLabel.text = OnboardingStrings.backupOptionScreenshot
        copyBackupLabel.text = OnboardingStrings.backupOptionCopy
        paperBackupLabel.text = OnboardingStrings.backupOptionPaper
        goBackLabel.text = OnboardingStrings.backupGoBackOption
    }
}
