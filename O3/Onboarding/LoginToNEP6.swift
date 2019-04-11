//
//  LoginToNEP6.swift
//  O3
//
//  Created by Andrei Terentiev on 10/29/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import KeychainAccess
import SwiftTheme
import Neoutils

protocol LoginToNEP6ViewControllerDelegate {
    func authorized(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
}

class LoginToNep6ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var animationViewContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    let animation = LOTAnimationView(name: "RocketSplash")
    let nep6 = NEP6.getFromFileSystem()
    var delegate: LoginToNEP6ViewControllerDelegate?
    var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    func setGradient() {
        let gradient: CAGradientLayer = CAGradientLayer()
       gradient.colors = [UIColor(hexString:"#002D5DFF")!.cgColor, UIColor(hexString: "#00A2EEFF")!.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = view.layer.frame
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    func setAccountDetails(_ account: Wallet) {
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
    }
    
    func login() {
        if NEP6.getFromFileSystem() != nil  {
            O3KeychainManager.getSigningKeyPassword { result in
                O3HUD.start()
                switch result {
                case .success(let nep6Pass):
                    let nep6 = NEP6.getFromFileSystem()!
                    var error: NSError?
                    for accountLoop in nep6.accounts {
                        if accountLoop.isDefault {
                            let account = Wallet(wif: NeoutilsNEP2Decrypt(accountLoop.key, nep6Pass, &error))!
                            self.setAccountDetails(account)
                        }
                    }
                case .failure(_):
                    return
                }
            }
        } else {
            O3KeychainManager.getWifKey { result in
                O3HUD.start()
                switch result {
                case .success(let wif):
                    let account = Wallet(wif: wif)!
                    self.setAccountDetails(account)
                case .failure(_):
                    return
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGradient()
        animationViewContainer.embed(animation)
        animation.loopAnimation = true
        animation.play()
        tableView.delegate = self
        tableView.dataSource = self
        setLocalizedStrings()
        login()
    }
    
    func inputPassword(encryptedKey: String, name: String) {
        let alertController = UIAlertController(title: String(format: "Login to %@", name), message: "Enter the password you used to secure this wallet", preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text
            var error: NSError?
                if let wif = NeoutilsNEP2Decrypt(encryptedKey, inputPass, &error) {
                    NEP6.makeNewDefault(key: encryptedKey, pass: inputPass!)
                    self.login()
                } else {
                    OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {}
            
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nep6 != nil {
            return nep6!.getWalletAccounts().count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "walletNameTableViewCell")
        let label = cell?.viewWithTag(1) as? UILabel
        let unlockedImage = cell?.viewWithTag(2) as? UIImageView
        if nep6 != nil {
            let account = nep6?.getWalletAccounts()[indexPath.row]
            label?.text = account!.label
            if account!.isDefault {
                unlockedImage?.isHidden = false
            } else {
                unlockedImage?.isHidden = true
            }
        } else {
            label?.text = "My O3 Wallet"
            unlockedImage?.isHidden = false
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if nep6 == nil {
            login()
            return
        }
        
        
        let account = (nep6?.getWalletAccounts()[indexPath.row])!
        if account.isDefault == true {
            login()
        } else {
            inputPassword(encryptedKey: account.key!, name: account.label)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return OnboardingStrings.walletSelectTitle
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.backgroundView?.backgroundColor = .clear
        header.textLabel?.textColor = .white
        header.textLabel?.font = UIFont(name: "Avenir", size: 14)
    }
    
    func setLocalizedStrings() {
        titleLabel.text = OnboardingStrings.welcomeBackTitle.uppercased()
        subtitleLabel.text = OnboardingStrings.welcomeBackSubtitle
    }
}
