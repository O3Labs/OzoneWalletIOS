//
//  LoginToCurrentWalletViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/28/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import KeychainAccess
import LocalAuthentication
import SwiftTheme
import Neoutils

protocol LoginToCurrentWalletViewControllerDelegate {
    func authorized(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
}

class LoginToCurrentWalletViewController: UIViewController {

    @IBOutlet var loginButton: UIButton?
    @IBOutlet var mainImageView: UIImageView?
    @IBOutlet weak var cancelButton: UIButton!

    var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    var delegate: LoginToCurrentWalletViewControllerDelegate?
    func login() {
        let keychain = Keychain(service: "network.o3.neo.wallet")
        DispatchQueue.global().async {
            do {
                var nep6Pass: String? = nil
                var key: String? = nil
                if NEP6.getFromFileSystem() != nil {
                    nep6Pass = try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .authenticationPrompt(OnboardingStrings.authenticationPrompt)
                        .get(AppState.protectedKeyValue)
                } else {
                    key = try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .authenticationPrompt(OnboardingStrings.authenticationPrompt)
                        .get(AppState.protectedKeyValue)
                }

                if key == nil && nep6Pass == nil {
                    return
                }
                
                var account: Wallet!
                if key != nil {
                    account = Wallet(wif: key!)!
                } else {
                    let nep6 = NEP6.getFromFileSystem()
                    var error: NSError?
                    for accountLoop in nep6!.accounts {
                        if accountLoop.isDefault {
                            account = Wallet(wif: NeoutilsNEP2Decrypt(accountLoop.key, nep6Pass, &error))!
                        }
                    }
                }
                O3HUD.start()
                Authenticated.wallet = account
                DispatchQueue.global(qos: .background).async {
                    if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                        AppState.bestSeedNodeURL = bestNode
                    }
                    DispatchQueue.main.async {
                        O3HUD.stop {
                            DispatchQueue.main.async {
                                SwiftTheme.ThemeManager.setTheme(index: UserDefaultsManager.themeIndex)
                                //instead of doing segue here. we need to init the whole rootViewController

                                UIView.transition(with: UIApplication.appDelegate.window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    let oldState: Bool = UIView.areAnimationsEnabled
                                    UIView.setAnimationsEnabled(false)
                                    UIApplication.appDelegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                                    UIView.setAnimationsEnabled(oldState)

                                }, completion: { (finished: Bool) -> Void in
                                    if finished {
                                        self.delegate?.authorized(launchOptions: self.launchOptions)
                                    }
                                })
                            }
                        }
                    }
                }
            } catch _ {

            }
        }
    }
    override func viewDidLoad() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.viewDidLoad()
        setLocalizedStrings()
        login()
    }

    func performLogout() {
        O3Cache.clear()
        try? Keychain(service: "network.o3.neo.wallet").remove(AppState.protectedKeyValue)
        try? Keychain(service: "network.o3.neo.wallet").remove(AppState.protectedKeyValue)
        Authenticated.wallet = nil
        UserDefaultsManager.o3WalletAddress = nil
        SwiftTheme.ThemeManager.setTheme(index: 0)
        UserDefaultsManager.themeIndex = 0
        NotificationCenter.default.post(name: Notification.Name("loggedOut"), object: nil)
        self.dismiss(animated: false)
    }

    @IBAction func didTapLogin(_ sender: Any) {
        login()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        OzoneAlert.confirmDialog(message: SettingsStrings.logoutWarning, cancelTitle: OzoneAlert.cancelNegativeConfirmString, confirmTitle: SettingsStrings.logout, didCancel: {

        }, didConfirm: {
            self.performLogout()
            self.view.window!.rootViewController?.dismiss(animated: false)
            UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Onboarding", bundle: nil).instantiateInitialViewController()

        })
    }

    func setLocalizedStrings() {
        cancelButton.setTitle(SettingsStrings.logout, for: UIControl.State())
        if #available(iOS 8.0, *) {
            var error: NSError?
            let hasTouchID = LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
            //if touchID is unavailable.
            //change the caption of the button here.
            if hasTouchID == false {
                loginButton?.setTitle(OnboardingStrings.loginWithExistingPasscode, for: .normal)
            } else {
                loginButton?.setTitle(OnboardingStrings.loginWithExistingBiometric, for: .normal)
            }
        }
    }
}
