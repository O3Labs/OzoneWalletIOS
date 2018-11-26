//
//  SettingsMenuTableViewControllwe.swift
//  O3
//
//  Created by Andrei Terentiev on 9/26/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import KeychainAccess
import UIKit
import SwiftTheme
import KeychainAccess
import WebBrowser
import ZendeskSDK
import Neoutils

class SettingsMenuTableViewController: UITableViewController, HalfModalPresentable, WebBrowserDelegate {
    @IBOutlet weak var contactView: UIView!
    @IBOutlet weak var themeCell: UITableViewCell!
    @IBOutlet weak var currencyCell: UITableViewCell!
    @IBOutlet weak var contactCell: UITableViewCell!
    @IBOutlet weak var supportCell: UITableViewCell!
    @IBOutlet weak var enableMultiWalletCell: UITableViewCell!
    @IBOutlet weak var idCell: UITableViewCell!
    
    @IBOutlet weak var supportView: UIView!
    @IBOutlet weak var currencyView: UIView!
    @IBOutlet weak var themeView: UIView!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var supportLabel: UILabel!
    @IBOutlet weak var multiWalletLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var qrView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var walletNameLabel: UILabel!

    @IBOutlet weak var congestionIcon: UIImageView!
    
    
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate

    func saveQRCodeImage() {
        let qrWithBranding = UIImage.imageWithView(view: self.qrView
        )
        UIImageWriteToSavedPhotosAlbum(qrWithBranding, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func addWalletChangeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWalletInfo(_:)), name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "NEP6Updated"), object: nil)
    }
    
    func share() {
        let shareURL = URL(string: "https://o3.app/" + (Authenticated.wallet?.address)!)
        let qrWithBranding = UIImage.imageWithView(view: self.qrView)
        let activityViewController = UIActivityViewController(activityItems: [shareURL as Any, qrWithBranding], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveQR = UIAlertAction(title: AccountStrings.saveQRAction, style: .default) { _ in
            self.saveQRCodeImage()
        }
        alert.addAction(saveQR)
        let copyAddress = UIAlertAction(title: AccountStrings.copyAddressAction, style: .default) { _ in
            UIPasteboard.general.string = Authenticated.wallet?.address
            //maybe need some Toast style to notify that it's copied
        }
        alert.addAction(copyAddress)
        let share = UIAlertAction(title: AccountStrings.shareAction, style: .default) { _ in
            self.share()
        }
        alert.addAction(share)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = addressLabel
        present(alert, animated: true, completion: nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: OzoneAlert.errorTitle, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default))
            present(alert, animated: true)
        } else {
            //change it to Toast style.
            let alert = UIAlertController(title: AccountStrings.saved, message: AccountStrings.savedMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default))
            present(alert, animated: true)
        }
    }
    
    
    var themeString = UserDefaultsManager.themeIndex == 0 ? SettingsStrings.classicTheme: SettingsStrings.darkTheme {
        didSet {
            self.setThemeLabel()
        }
    }

    func setThemeLabel() {
        guard let label = themeCell.viewWithTag(1) as? UILabel else {
            fatalError("Undefined behavior with table view")
        }
        DispatchQueue.main.async { label.text = self.themeString }
    }
    
    func checkCongestion() {
        NeoClient(seed: AppState.bestSeedNodeURL).getMempoolHeight() { (result) in
            switch result {
            case .failure(let error):
                return
            case .success(let pending):
                DispatchQueue.main.async {
                    if pending > 1000 {
                        self.congestionIcon.isHidden = false
                        self.headerTitleLabel.text = String(format: SettingsStrings.congestionWarning, pending)
                        self.headerTitleLabel.textColor = Theme.light.accentColor
                    }
                }
            }
        }
    }
    
    @objc func updateWalletInfo(_ sender: Any?) {
        qrView.image = UIImage.init(qrData: (Authenticated.wallet?.address)!, width: qrView.bounds.size.width, height: qrView.bounds.size.height)
        addressLabel.text = (Authenticated.wallet?.address)!
        if let nep6 = NEP6.getFromFileSystem() {
            let defaultIndex = nep6.accounts.index { $0.isDefault == true }
            self.navigationController?.navigationBar.topItem?.title = nep6.accounts[defaultIndex!].label
        } else {
            self.navigationController?.navigationBar.topItem?.title = "My O3 Wallet"
        }
        
        if NEP6.getFromFileSystem() == nil {
            multiWalletLabel.text = SettingsStrings.enableMultiWallet
        } else {
            multiWalletLabel.text = SettingsStrings.manageWallets
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setThemedElements()
        setLocalizedStrings()
        applyNavBarTheme()
        addWalletChangeObserver()
        updateWalletInfo(nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showActionSheet))
        self.headerView.addGestureRecognizer(tap)
        contactView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sendMail)))
        supportView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSupportForum)))
        themeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeTheme)))
        enableMultiWalletCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(enableMultiWallet)))
        idCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openIdentity)))
        setThemeLabel()

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = String(format: SettingsStrings.versionLabel, version)
        }
    }
    
    @objc func openIdentity() {
        self.performSegue(withIdentifier: "segueToIdentitiesList", sender: nil)
    }
    
    @objc func enableMultiWallet() {
        if NEP6.getFromFileSystem()?.accounts == nil {
            self.performSegue(withIdentifier: "segueToMultiWalletActivation", sender: nil)
        } else {
            self.performSegue(withIdentifier: "segueToManageWallets", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToManageWallets" || segue.identifier == "segueToIdentitiesList" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCongestion()
        currencyLabel.text = String(format: SettingsStrings.currencyTitle, UserDefaultsManager.referenceFiatCurrency.rawValue.uppercased())
    }

    @objc func maximize(_ sender: Any) {
        maximizeToFullScreen()
    }

    @objc func changeTheme() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let lightThemeAction = UIAlertAction(title: SettingsStrings.classicTheme, style: .default) { _ in
            UserDefaultsManager.themeIndex = 0
            ThemeManager.setTheme(index: 0)
            self.themeString = SettingsStrings.classicTheme
        }

        let darkThemeAction = UIAlertAction(title: SettingsStrings.darkTheme, style: .default) { _ in
            UserDefaultsManager.themeIndex = 1
            ThemeManager.setTheme(index: 1)
            self.themeString = SettingsStrings.darkTheme
        }

        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
        }

        optionMenu.addAction(lightThemeAction)
        optionMenu.addAction(darkThemeAction)
        optionMenu.addAction(cancelAction)

        optionMenu.popoverPresentationController?.sourceView = themeView
        present(optionMenu, animated: true, completion: nil)
    }

    @objc func sendMail() {
        let config = RequestUiConfiguration()
        config.subject = "iOS Support"
        config.tags = [UIDevice.current.modelName, UIDevice.current.systemVersion,
                       Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String ]
        let viewController = RequestUi.buildRequestUi(with: [config])
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func openSupportForum() {
        let webBrowserViewController = WebBrowserViewController()

        webBrowserViewController.delegate = self
        webBrowserViewController.isToolbarHidden = true
        webBrowserViewController.title = ""
        webBrowserViewController.isShowURLInNavigationBarWhenLoading = false
        webBrowserViewController.barTintColor = UserDefaultsManager.theme.backgroundColor
        webBrowserViewController.tintColor = Theme.light.primaryColor
        webBrowserViewController.isShowPageTitleInNavigationBar = false
        webBrowserViewController.loadURLString("https://community.o3.network")
        maximizeToFullScreen(allowReverse: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigationController?.pushViewController(webBrowserViewController, animated: true)
        }
    }

    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func performLogoutCleanup() {
        O3Cache.clear()
        SwiftTheme.ThemeManager.setTheme(index: 0)
        UserDefaultsManager.themeIndex = 0
        try? Keychain(service: "network.o3.neo.wallet").remove("ozonePrivateKey")
        try? Keychain(service: "network.o3.neo.wallet").remove("ozoneActiveNep6Password")
        NEP6.removeFromDevice()
        Authenticated.wallet = nil
        UserDefaultsManager.o3WalletAddress = nil
        NotificationCenter.default.post(name: Notification.Name("loggedOut"), object: nil)
        self.dismiss(animated: false)
        let o3tab =  UIApplication.shared.keyWindow?.rootViewController as? O3TabBarController

        //Chance these aren't nil yet which leads to reference cycke
        o3tab?.halfModalTransitioningDelegate?.viewController = nil
        o3tab?.halfModalTransitioningDelegate?.presentingViewController = nil
        o3tab?.halfModalTransitioningDelegate?.interactionController = nil
        o3tab?.halfModalTransitioningDelegate = nil

    }

    //properly implement cell did tap
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setThemedElements() {
        let themedTitleLabels = [contactLabel, themeLabel, currencyLabel, versionLabel, supportLabel, multiWalletLabel, walletNameLabel, idLabel]
        let themedCells = [themeCell, currencyCell, contactCell, idCell]
        for cell in themedCells {
            cell?.contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
            cell?.theme_backgroundColor = O3Theme.backgroundColorPicker
        }
        
        for label in themedTitleLabels {
            label?.theme_textColor = O3Theme.titleColorPicker
        }
        versionLabel?.theme_textColor = O3Theme.lightTextColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        headerView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    

    func setLocalizedStrings() {
        themeLabel.text = SettingsStrings.themeTitle
        currencyLabel.text = SettingsStrings.currencyTitle + UserDefaultsManager.referenceFiatCurrency.rawValue.uppercased()
        contactLabel.text = SettingsStrings.contactTitle
        supportLabel.text = SettingsStrings.supportTitle
        versionLabel.text = SettingsStrings.versionLabel
        idLabel.text = SettingsStrings.idLabel
        if NEP6.getFromFileSystem() == nil {
            multiWalletLabel.text = SettingsStrings.enableMultiWallet
        } else {
            multiWalletLabel.text = SettingsStrings.manageWallets
        }
        headerTitleLabel.text = AccountStrings.myAddressInfo
    }
}
