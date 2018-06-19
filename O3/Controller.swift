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
        let nav = WalletHomeNavigationController(rootViewController: sendModal)
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        nav.navigationBar.prefersLargeTitles = true
        nav.navigationItem.largeTitleDisplayMode = .automatic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIApplication.appDelegate.window?.rootViewController?.present(nav, animated: true, completion: {
                sendModal.assetSelected(selected: selectedAsset, gasBalance: O3Cache.gas().value)
                sendModal.toAddressField.text = to
                if amount != nil {
                    sendModal.amountField.text = String(format: "%@", amount!)
                }
            })
        }
    }
}
