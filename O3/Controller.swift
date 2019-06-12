//
//  Controller.swift
//  O3
//
//  Created by Apisit Toompakdee on 6/12/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import DeckTransition

class Controller: NSObject {

    func openSwitcheoDapp() {
        let url = URL(string: "http://analytics.o3.network/redirect/?url=https://switcheo.exchange/?ref=o3")
        openDappBrowser(url: url!, modal: true, moreButton: true)
    }
    
    let transitionDelegate = DeckTransitioningDelegate()
    func openDappBrowser(url: URL, modal: Bool, moreButton: Bool = false, deck: Bool = false, assetSymbol: String? = nil) {

        let top = UIApplication.topViewController()
        if  top == nil {
            return
        }

        let nav = UIStoryboard(name: "Browser", bundle: nil).instantiateInitialViewController() as? UINavigationController
        if let vc = nav!.viewControllers.first as? DAppBrowserViewController {
            vc.url = url
            vc.showMoreButton = moreButton
            vc.selectedAssetSymbol = assetSymbol
            if deck == true {
                nav!.transitioningDelegate = transitionDelegate
                nav!.modalPresentationStyle = .custom
            }
            if modal == true {
                top!.present(nav!, animated: true, completion: nil)
            } else {
                if top == nil {
                    return
                }
                if let selectedNav = top as? UINavigationController {
                    selectedNav.hidesBottomBarWhenPushed = true
                    selectedNav.pushViewController(vc, animated: true)
                }
            }

        }
    }
    
    func openDappBrowserV2(url: URL, assetSymbol: String? = nil) {
        let top = UIApplication.topViewController()
        if  top == nil {
            return
        }
        
        let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateInitialViewController() as? UINavigationController
        if let vc = nav!.viewControllers.first as?
            dAppBrowserV2ViewController {
            let viewModel = dAppBrowserViewModel()
            viewModel.url = url
            if assetSymbol != nil {
                viewModel.assetSymbol = assetSymbol
            }
            vc.viewModel = viewModel
        }
        
        top!.present(nav!, animated: true, completion: nil)
    }

    func openSend(to: String, selectedAsset: TransferableAsset, amount: String?) {

        guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "sendWhereTableViewController") as? SendWhereTableViewController else {
            fatalError("Presenting improper modal controller")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let tabbar = UIApplication.appDelegate.window?.rootViewController as? O3TabBarController else {
                return
            }

            let nav = NoHairlineNavigationController(rootViewController: sendModal)

            //This is to use current tabbar to hold strong reference of the deck transition's animation
            //otherwise, it won't open with deck transition
            nav.transitioningDelegate = tabbar.transitionDelegate
            nav.modalPresentationStyle = .custom
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationItem.largeTitleDisplayMode = .never
            tabbar.present(nav, animated: true, completion: {
                //sendModal.assetSelected(selected: selectedAsset, gasBalance: O3Cache.gas().value)
                sendModal.addressTextField.text = to
                if amount != nil {
                  //  sendModal.amountField.text = String(format: "%@", amount!)
                }
            })
        }
    }
    
    func openSecurityCenter() {
        focusOnTab(tabIndex: 4)
        guard let walletInfoModal = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "manageWalletTableViewController") as? SecurityCenterTableViewController else {
            fatalError("Presenting improper view controller")
        }
        
        walletInfoModal.account = NEP6.getFromFileSystem()?.getAccounts().first { $0.isDefault }!
        let nav = UINavigationController()
        nav.viewControllers = [walletInfoModal]
        UIApplication.topViewController()!.present(nav, animated: true)
    }
    
    func openMyAddress() {
        guard let tabbar = UIApplication.appDelegate.window?.rootViewController as? O3TabBarController else {
            return
        }
        
        let modal = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "MyAddressNavigationController")
        modal.transitioningDelegate = tabbar.transitionDelegate
        modal.modalPresentationStyle = .custom
        UIApplication.topViewController()!.present(modal, animated: true, completion: nil)
    }
    
    func focusOnTab(tabIndex: Int) {
        guard let tabbar = UIApplication.appDelegate.window?.rootViewController as? O3TabBarController else {
            return
        }
        tabbar.selectedIndex = tabIndex
    }
    
    func openWalletSelector(isPortfolio: Bool = true ) {
        let modal = UIStoryboard(name: "WalletSelector", bundle: nil).instantiateInitialViewController() as! UINavigationController
        (modal.children.first as! WalletSelectorTableViewController).isPortfolio = isPortfolio
        UIApplication.topViewController()!.present(modal, animated: true, completion: nil)
    }
    
    func openAddNewWallet() {
        let modal = UIStoryboard(name: "AddNewMultiWallet", bundle: nil).instantiateInitialViewController()
        UIApplication.topViewController()!.present(modal!, animated: true, completion: nil)
    }
}
