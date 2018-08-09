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
    
    func openDappBrowser(url: URL, modal: Bool, moreButton:Bool = false) {
        
        let top = UIApplication.topViewController()
        if  top == nil {
            return
        }
        
        let nav = UIStoryboard(name: "Browser", bundle: nil).instantiateInitialViewController() as! UINavigationController
        if let vc = nav.viewControllers.first as? DAppBrowserViewController {
            vc.url = url
            vc.showMoreButton = moreButton
            if modal == true {
                top!.present(nav, animated: true, completion: nil)
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
    
    func openSend(to: String, selectedAsset: TransferableAsset, amount: String?) {

        guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "SendTableViewController") as? SendTableViewController else {
            fatalError("Presenting improper modal controller")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let tabbar = UIApplication.appDelegate.window?.rootViewController as? O3TabBarController else {
                return
            }

            let nav = WalletHomeNavigationController(rootViewController: sendModal)

            //This is to use current tabbar to hold strong reference of the deck transition's animation
            //otherwise, it won't open wiht deck transition
            nav.transitioningDelegate = tabbar.transitionDelegate
            nav.modalPresentationStyle = .custom
            nav.navigationBar.prefersLargeTitles = true
            nav.navigationItem.largeTitleDisplayMode = .automatic

            tabbar.present(nav, animated: true, completion: {
                sendModal.assetSelected(selected: selectedAsset, gasBalance: O3Cache.gas().value)
                sendModal.toAddressField.text = to
                if amount != nil {
                    sendModal.amountField.text = String(format: "%@", amount!)
                }
            })
        }
    }
}
