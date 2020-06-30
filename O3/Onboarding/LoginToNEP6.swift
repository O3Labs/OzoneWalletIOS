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
import PKHUD

protocol LoginToNEP6ViewControllerDelegate {
    func authorized(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
}

class LoginToNep6ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var animationViewContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var createWalletButton: UIButton!
    
    let animation = LOTAnimationView(name: "RocketSplash")
    var nep6 = NEP6.getFromFileSystem()
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
    
    func enterPortfolio() {
        DispatchQueue.global(qos: .background).async {
            if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                AppState.bestSeedNodeURL = bestNode
            }
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
    
    
    func loginLegacy() {
        if let vc = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "CreateWalletTableViewController") as? CreateWalletTableViewController {
            let vcWithNav = (UINavigationController(rootViewController: vc))
            self.present(vcWithNav, animated: true, completion: {})
            return
        }
    }
    
    func login(account: NEP6.Account) {
        if O3KeychainManager.containsLegacyNep6() {
            forceMigrate()
            return
        }
        
        let prompt = String(format: OnboardingStrings.nep6AuthenticationPrompt, account.label)
        
        O3KeychainManager.getWalletForNep6(for: account.address) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let wallet):
                    let currtime = Date().timeIntervalSince1970
                    NEP6.makeNewDefault(key: account.key!, wallet: wallet)
                    print(Date().timeIntervalSince1970 - currtime)
                    self.enterPortfolio()
                case .failure(let e):
                    return
                }
            }
        }
    }
    @IBAction func createButtonClick(_ sender: UIButton) {
        let alertController = UIAlertController(title: "create a new wallet", message:"After the wallet is created, all the original wallet data will be cleared and cannot be retrieved. Can you confirm to create the wallet?" , preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "confirm", style: .default) { _ in
            NEP6.removeFromDevice()
            O3Cache.clear()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.nep6 == nil {
                    self.loginLegacy()
                    return
                }
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel) { _ in
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createWalletButton.setTitle("create a new wallet", for: .normal)
        self.createWalletButton.setTitleColor(.white, for: .normal)
        setGradient()
        animationViewContainer.embed(animation)
        animation.loopAnimation = true
        animation.play()
        tableView.delegate = self
        tableView.dataSource = self
        setLocalizedStrings()
        if NEP6.getFromFileSystem() == nil {
            loginLegacy()
            return
        } else {
            login(account: (NEP6.getFromFileSystem()?.getAccounts().first {$0.isDefault})!)
        }
    }
    
    func forceMigrate() {
        let defaultAccount = (NEP6.getFromFileSystem()?.getAccounts().first {$0.isDefault})!
        O3KeychainManager.getSigningKeyPassword(with: "Security updated. Please authenticate to login again") { result in
            switch result {
            case .success(let pass):
                O3KeychainManager.setNep6DecryptionPassword(for: defaultAccount.address, pass: pass) { result in
                    switch result {
                    case .success:
                        O3KeychainManager.removeLegacySigningKey { result in
                            switch result {
                            case .success:
                                self.login(account: (NEP6.getFromFileSystem()?.getAccounts().first {$0.isDefault})!)
                            case .failure(let e):
                                return
                            }
                            
                        }
                    case .failure(let e):
                        return
                    }
                }
            case .failure(let e):
                return
            }
        }
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nep6 = NEP6.getFromFileSystem()
        if nep6 != nil {
            return nep6!.getWalletAccounts().count
        } else {
            return 1
        }
    }
    
    func recoverKeys() {
        
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
            return cell!
        } else {
            label?.text = "My O3 Wallet"
            unlockedImage?.isHidden = false
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if nep6 == nil {
            loginLegacy()
            return
        }
        
        let account = (nep6?.getWalletAccounts()[indexPath.row])!
        login(account: account)
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
