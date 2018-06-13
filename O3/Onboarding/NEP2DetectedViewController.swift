//
//  NEP2DetectedViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/8/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import PKHUD
import Neoutils

protocol Nep2PasswordDelegate: class {
    func passwordEntered(account: Account?)
}

class NEP2DetectedViewController: UIViewController {
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var animationContainer: UIView!
    @IBOutlet weak var nep2PasswordField: UITextField!

    var nep2EncryptedKey: String = ""
    var password = ""

    let animationView = LOTAnimationView(name: "EnterPasswordKey")
    weak var delegate: Nep2PasswordDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        nep2PasswordField.becomeFirstResponder()
        nep2PasswordField.setLeftPaddingPoints(CGFloat(10.0))
        nep2PasswordField.setRightPaddingPoints(CGFloat(10.0))

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)
        view.bringSubview(toFront: alertContainer)

        doneButton.isEnabled = false

        animationContainer.embed(animationView)
        animationView.loopAnimation = true
        animationView.play()
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            HUD.show(.progress, onView: self.alertContainer)
        }

        var error: NSError?
        DispatchQueue.global().async {
            let wif = NeoutilsNEP2Decrypt(self.nep2EncryptedKey, self.password, &error)
            if wif == nil {
                DispatchQueue.main.async {
                    HUD.hide()
                    OzoneAlert.alertDialog(message: OnboardingStrings.invalidKey, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                        self.view.endEditing(true)
                        self.dismiss(animated: true) {
                            self.delegate?.passwordEntered(account: nil)
                        }
                    }
                }
                return
            }

            guard let account = Account(wif: wif!) else {
                DispatchQueue.main.async {
                    HUD.hide()
                    OzoneAlert.alertDialog(message: OnboardingStrings.invalidKey, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                        self.view.endEditing(true)
                        self.dismiss(animated: true) {
                            self.delegate?.passwordEntered(account: nil)
                        }
                    }
                }
                return
            }

            DispatchQueue.main.async {
                self.view.endEditing(true)
                self.dismiss(animated: true) {
                    self.delegate?.passwordEntered(account: account)
                }
            }
        }
    }

    @IBAction func passwordTyped(_ sender: Any) {
        password = (self.nep2PasswordField.text?.trim())!
        if password == "" {
            doneButton.isEnabled = false
            doneButton.backgroundColor = Theme.light.disabledColor
        } else {
            doneButton.isEnabled = true
            doneButton.backgroundColor = Theme.light.positiveGainColor
        }
    }

    func setLocalizedStrings() {
        titleView.text = OnboardingStrings.encryptedKeyDetected
        subtitleLabel.text = OnboardingStrings.pleaseEnterNEP2Password
        doneButton.setTitle(OnboardingStrings.submit, for: UIControlState())
    }
}
