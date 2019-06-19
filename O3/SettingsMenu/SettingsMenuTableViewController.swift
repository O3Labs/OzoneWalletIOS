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
import DeckTransition
import ZendeskSDK
import Neoutils

class SettingsMenuTableViewController: UITableViewController, HalfModalPresentable, WebBrowserDelegate {
    @IBOutlet weak var generalSettingsCell: UITableViewCell!
    @IBOutlet weak var supportCell: UITableViewCell!
    @IBOutlet weak var enableMultiWalletCell: UITableViewCell!
    @IBOutlet weak var manageCoinbaseTableViewCell: UITableViewCell!
    
    @IBOutlet weak var helpView: UIView!
    @IBOutlet weak var generalSettingsView: UIView!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var generalSettingsLabel: UILabel!
    @IBOutlet weak var helpLabel: UILabel!
    @IBOutlet weak var multiWalletLabel: UILabel!
    @IBOutlet weak var manageCoinbaseLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var qrView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!

    @IBOutlet weak var congestionIcon: UIImageView!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var referButton: UIButton!
    
    @IBOutlet weak var privacyPolicyLabel: UILabel!
    @IBOutlet weak var footerView: UIView!
    
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
    
    func setTitleButton() {
        var titleViewButton = UIButton(type: .system)
        let activeWallet = NEP6.getFromFileSystem()!.getAccounts().first {$0.isDefault}!.label
        titleViewButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControl.State())
        titleViewButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 16)!
        titleViewButton.setTitle(activeWallet, for: .normal)
        titleViewButton.semanticContentAttribute = .forceRightToLeft
        titleViewButton.setImage(UIImage(named: "ic_chevron_down"), for: UIControl.State())
        
        titleViewButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20 )
        // Create action listener
        titleViewButton.addTarget(self, action: #selector(openMultiWalletDisplay), for: .touchUpInside)
        navigationItem.titleView = titleViewButton
    }
    
    @objc func updateWalletInfo(_ sender: Any?) {
        DispatchQueue.main.async {
            self.qrView.image = UIImage.init(qrData: (Authenticated.wallet?.address)!, width: self.qrView.bounds.size.width, height: self.qrView.bounds.size.height)
            self.addressLabel.text = (Authenticated.wallet?.address)!
            self.setTitleButton()
            
            self.multiWalletLabel.text = SettingsStrings.manageWallets
        }
    }
    
    @objc func leftBarButtonTapped(_ sender: Any) {
        let inboxController = UIStoryboard(name: "Inbox", bundle: nil).instantiateInitialViewController()!
        self.present(inboxController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.qrView.image = UIImage.init(qrData: (Authenticated.wallet?.address)!, width: self.qrView.bounds.size.width, height: self.qrView.bounds.size.height)
        
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "support"), style: .plain, target: self, action: #selector(leftBarButtonTapped(_:)))
        
        setThemedElements()
        setLocalizedStrings()
        applyNavBarTheme()
        addWalletChangeObserver()
        updateWalletInfo(nil)
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(showActionSheet))
        self.headerView.addGestureRecognizer(tap)
        
        helpView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSupportForum)))
        generalSettingsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openGeneralSettings)))
        enableMultiWalletCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToSecurityCenter)))
        manageCoinbaseTableViewCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToManageCoinbase)))
        footerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPrivacyPolicy)))
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = String(format: SettingsStrings.versionLabel, version)
        }
        setTitleButton()
    }
    
    @objc func openPrivacyPolicy() {
        Controller().openDappBrowserV2(url: URL(string:
            "https://o3.network/privacy/")!)
    }
    
    @objc func openMultiWalletDisplay() {
        Controller().openWalletSelector()
    }
    
    @IBAction func buyNeo(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let buyWithFiat = UIAlertAction(title: "With Fiat", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://buy.o3.network/?a=" + (Authenticated.wallet?.address)!)!)
            RevenueEvent.shared.buyInitiated(buyWith: "fiat", source: "settings")
        }
        actionSheet.addAction(buyWithFiat)
        
        let buyWithCrypto = UIAlertAction(title: "With Crypto", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://swap.o3.app")!)
            RevenueEvent.shared.buyInitiated(buyWith: "crypto", source: "settings")

        }
        actionSheet.addAction(buyWithCrypto)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func referNeo(_ sender: Any) {
        RevenueEvent.shared.shareReferral()
        let nav = UIStoryboard(name: "Disclaimers", bundle: nil).instantiateViewController(withIdentifier: "referralBottomSheet")
        let transitionDelegate = DeckTransitioningDelegate()
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = transitionDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func goToSecurityCenter() {
        self.performSegue(withIdentifier: "segueToSecurityCenter", sender: nil)
    }
    
    @objc func goToManageCoinbase() {
        self.performSegue(withIdentifier: "segueToManageCoinbase", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? UINavigationController else {
                fatalError("Something went terribly wrong")
        }
        
        if let child = nav.children[0] as? SecurityCenterTableViewController {
            child.account = NEP6.getFromFileSystem()!.getDefaultAccount()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaultsManager.needsInboxBadge {
            self.navigationItem.leftBarButtonItem!.setBadge(text: " ")
        } else {
            self.navigationItem.leftBarButtonItem!.setBadge(text: "")
        }
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async { self.setGradients() }
    }

    @objc func maximize(_ sender: Any) {
        maximizeToFullScreen()
    }

    @objc func openGeneralSettings() {
        guard let walletInfoModal = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "generalSettingsTableViewController") as? GeneralSettingsTableViewController else {
            
            fatalError("Presenting improper view controller")
        }
        
    
        let nav = UINavigationController()
        nav.viewControllers = [walletInfoModal]
        UIApplication.topViewController()!.present(nav, animated: true)
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
        guard let walletInfoModal = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "helpTableViewController") as? HelpTableViewController else {
            
            fatalError("Presenting improper view controller")
        }
        
        
        let nav = UINavigationController()
        nav.viewControllers = [walletInfoModal]
        UIApplication.topViewController()!.present(nav, animated: true)
    }

    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    //properly implement cell did tap
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func setThemedElements() {
        let themedTitleLabels = [generalSettingsLabel, versionLabel, helpLabel, multiWalletLabel, manageCoinbaseLabel]
        let themedCells = [generalSettingsCell, manageCoinbaseTableViewCell]
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
    
    func setGradients() {
        buyButton.setTitle("Buy NEO Today!", for: UIControl.State())
        referButton.setTitle("Refer friends and get rewards!", for: UIControl.State())
        
        let gradientBuy = CAGradientLayer()
        gradientBuy.frame = CGRect(x: 0, y: 0, width: buyButton.bounds.width, height: buyButton.bounds.height)
        gradientBuy.colors = [
            UIColor(red:0.57, green:0.88, blue:0, alpha:1).cgColor,
            UIColor(red:0.35, green:0.75, blue:0, alpha:1).cgColor]
        gradientBuy.locations = [0, 1]
        gradientBuy.startPoint = CGPoint(x: 1.0, y: 0.5)
        gradientBuy.endPoint = CGPoint(x: 0.5, y: 1)
        gradientBuy.cornerRadius = buyButton.cornerRadius
        buyButton.layer.insertSublayer(gradientBuy, at: 0)
        
        let gradientRefer = CAGradientLayer()
        gradientRefer.frame = CGRect(x: 0, y: 0, width: referButton.bounds.width, height: referButton.bounds.height)
        gradientRefer.colors = [
            UIColor(red:0.98, green:0.85, blue:0.38, alpha:1).cgColor,
            UIColor(red:0.97, green:0.45, blue:0.13, alpha:1).cgColor,
            UIColor(red:0.97, green:0.42, blue:0.11, alpha:1).cgColor
        ]
        gradientRefer.locations = [0, 0.93623286, 1]
        gradientRefer.startPoint = CGPoint(x: 1, y: 0.28)
        gradientRefer.endPoint = CGPoint(x: 0.42, y: 1)
        gradientRefer.cornerRadius = buyButton.cornerRadius
        referButton.layer.insertSublayer(gradientRefer, at: 0)
    }

    func setLocalizedStrings() {
        generalSettingsLabel.text = "General"
        helpLabel.text = "Help"
        versionLabel.text = SettingsStrings.versionLabel
        multiWalletLabel.text = SettingsStrings.manageWallets
        headerTitleLabel.text = AccountStrings.myAddressInfo
        privacyPolicyLabel.text = "Terms and privacy policy"
        manageCoinbaseLabel.text = "Manage Coinbase Account"
    }
}
