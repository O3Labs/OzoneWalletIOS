//
//  DappDisclaimerViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/9/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import M13Checkbox
import ActiveLabel

class DappDisclaimerViewController: UIViewController {
    @IBOutlet weak var warningImageView: UIImageView!
    @IBOutlet weak var warningTitleLabel: UILabel!
    @IBOutlet weak var warningDescriptionLabel: ActiveLabel!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var agreeButton: UIButton!
    
    @IBOutlet weak var checkboxContainer: UIView!
    @IBOutlet weak var checkboxDescription: UILabel!
    let checkbox = M13Checkbox(frame: CGRect(x: 0.0, y: 0.0, width: 24.0, height: 24.0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        
        warningImageView.tintColor = Theme.light.primaryColor
        checkbox.checkState = .checked
        checkboxContainer.embed(checkbox)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismissTapped()
    }
    
    @IBAction func returnToO3Tapped(_ sender: Any) {
        self.dismissTapped()
        self.presentingViewController?.dismissTapped()
    }
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        self.dismissTapped()
        if (checkbox.checkState == .checked) {
            UserDefaultsManager.hasAgreedDapps = true
        }
    }
    
    func setLocalizedStrings() {
        warningTitleLabel.text = "Welcome to O3's app browser"
        warningDescriptionLabel.customize { label in
            label.enabledTypes =  [ActiveType.custom(pattern: "\\Terms of service\\b")]
            label.text = "O3 app browser allows you connect with various dAPPs with your O3 Wallet. O3 is not responsible for any content related to third party apps. For more info please read our Terms of service"
            label.theme_textColor = O3Theme.lightTextColorPicker
            label.customColor = [ActiveType.custom(pattern: "\\Terms of service\\b"): Theme.light.primaryColor]
            label.handleCustomTap(for: ActiveType.custom(pattern: "\\Terms of service\\b"), handler: { url in UIApplication.shared.openURL(URL(string: "https://o3.network/privacy")!) })
        }
            
        checkboxDescription.text = "Don't show this again"
        returnButton.setTitle("Return to O3", for: UIControl.State())
        agreeButton.setTitle("Continue", for: UIControl.State())
    }
    
    func setThemedElements() {
        warningTitleLabel.theme_textColor = O3Theme.titleColorPicker
        warningDescriptionLabel.theme_textColor = O3Theme.lightTextColorPicker
        checkboxDescription.theme_textColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
}
