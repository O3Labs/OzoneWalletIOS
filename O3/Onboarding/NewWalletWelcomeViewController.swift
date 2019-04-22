//
//  NewWalletWelcomeViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 1/10/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class NewWalletWelcomeViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    
    let lottieAnimation = LOTAnimationView(name: "luna_bobbing")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lottieAnimation.loopAnimation = true
        lottieAnimation.play()
        containerView.embed(lottieAnimation)
        setLocalizedStrings()
    }
    @IBAction func continueTapped(_ sender: Any) {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }
    
    func setLocalizedStrings() {
        titleLabel.text = "Welcome to O3!"
        subtitleLabel.text = "You are all ready to go! The next thing to do is take a look around the app, get some tokens in your wallet and enjoy the Smart Economy.\n\nIf you need any help, let us know"
        continueButton.setTitle("Go To My Wallet", for: UIControl.State())
    }
}
