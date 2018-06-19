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

protocol LoginToCurrentWalletViewControllerDelegate {
    func authorized(launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
}

class LoginToCurrentWalletViewController: UIViewController {

    @IBOutlet var loginButton: UIButton?
    @IBOutlet var mainImageView: UIImageView?
    @IBOutlet weak var cancelButton: UIButton!

    var launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    var delegate: LoginToCurrentWalletViewControllerDelegate?

    func login() {
        let keychain = Keychain(service: "network.o3.neo.wallet")
        DispatchQueue.global().async {
            do {
                let key = try keychain
                    .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(OnboardingStrings.authenticationPrompt)
                    .get("ozonePrivateKey")
                if key == nil {
                    return
                }

                guard let account = Account(wif: key!) else {
                    return
                }
                O3HUD.start()
                Authenticated.account = account
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
        try? Keychain(service: "network.o3.neo.wallet").remove("ozonePrivateKey")
        Authenticated.account = nil
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
        cancelButton.setTitle(SettingsStrings.logout, for: UIControlState())
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
