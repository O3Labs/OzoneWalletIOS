//
//  WatchAddressAddedToMultiWalletTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class WatchAddressAddedToMultiWalletTableViewController: UITableViewController {
    
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var animationViewContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    let lottieView = LOTAnimationView(name: "wallet_generated")
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemeElements()
        animationViewContainer.embed(lottieView)
        lottieView.loopAnimation = true
        lottieView.play()
    }
    
    @IBAction func watchAddressFinishedTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        titleLabel.text = MultiWalletStrings.watchAddressAdded
        finishButton.setTitle(MultiWalletStrings.multiWalletFinished, for: UIControl.State())
    }
    
    func setThemeElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
