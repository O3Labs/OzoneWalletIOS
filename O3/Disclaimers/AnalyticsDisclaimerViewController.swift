//
//  AnalyticsDisclaimerViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 4/10/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import M13Checkbox
import ActiveLabel

class AnaylticsDisclaimerViewController: UIViewController {
    @IBOutlet weak var warningImageView: UIImageView!
    @IBOutlet weak var warningTitleLabel: UILabel!
    @IBOutlet weak var warningDescriptionLabel: ActiveLabel!
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
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        if (checkbox.checkState == .checked) {
            UserDefaultsManager.hasAgreedAnalytics = true
        }
        self.dismissTapped()
    }
    
    func setLocalizedStrings() {
        warningTitleLabel.text = "Welcome to O3"
        warningDescriptionLabel.customize { label in
            label.enabledTypes =  [ActiveType.custom(pattern: "\\Terms of service\\b")]
            label.text = "O3 tracks crash reports and usage statistics in order to improve its products. This data does not identify you, the user, by address or in any other identifiable way. By using this application you consent O3 to collect this info. For more info please read our Terms of Service"
            label.theme_textColor = O3Theme.lightTextColorPicker
            label.customColor = [ActiveType.custom(pattern: "\\Terms of service\\b"): Theme.light.primaryColor]
            label.handleCustomTap(for: ActiveType.custom(pattern: "\\Terms of service\\b"), handler: { url in UIApplication.shared.openURL(URL(string: "https://o3.network/privacy")!) })
        }
        
        checkboxDescription.text = "Don't show this again"
        agreeButton.setTitle("Continue", for: UIControl.State())
    }
    
    func setThemedElements() {
        warningTitleLabel.theme_textColor = O3Theme.titleColorPicker
        warningDescriptionLabel.theme_textColor = O3Theme.lightTextColorPicker
        checkboxDescription.theme_textColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
}

