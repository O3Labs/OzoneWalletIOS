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
