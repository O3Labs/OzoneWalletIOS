//
//  VerifyManualBackupViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 1/10/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import M13Checkbox

class VerifyManualBackupViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var screenshotLabel: UILabel!
    @IBOutlet weak var byHandLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    
    
    @IBOutlet weak var screenshotCheckbox: M13Checkbox!
    @IBOutlet weak var byHandCheckbox: M13Checkbox!
    @IBOutlet weak var otherCheckbox: M13Checkbox!
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var address: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenshotCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        byHandCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        otherCheckbox.addTarget(self, action: #selector(checkboxValueChanged(_:)), for: .valueChanged)
        
        for state in AppState.getManualVerifyType(address: address) {
            switch state {
                case .screenshot: screenshotCheckbox.setCheckState(.checked, animated: true)
                case .byHand: byHandCheckbox.setCheckState(.checked, animated: true)
                case .other: otherCheckbox.setCheckState(.checked, animated: true)
                default: break
            }
        }
        
        setThemedElements()
        setButtonEnableState()
        setLocalizedStrings()

    }
    
    func setButtonEnableState() {
        if screenshotCheckbox.checkState == .checked || byHandCheckbox.checkState == .checked || otherCheckbox.checkState == .checked {
            verifyButton.isEnabled = true
            verifyButton.theme_setTitleColor(O3Theme.primaryColorPicker, forState: UIControl.State())
        } else {
            verifyButton.isEnabled = false
            verifyButton.theme_setTitleColor(O3Theme.lightTextColorPicker, forState: UIControl.State())
        }
    }
    
    @objc func checkboxValueChanged(_ sender: M13Checkbox) {
        setButtonEnableState()
    }
    
    @IBAction func verifyTapped(_ sender: Any) {
        AppState.setDismissBackupNotification(dismiss: true)
        var types = [AppState.verificationType]()
        if screenshotCheckbox.checkState == .checked {
            types.append(AppState.verificationType.screenshot)
        }
        if byHandCheckbox.checkState == .checked {
            types.append(AppState.verificationType.byHand)
        }
        if otherCheckbox.checkState == .checked {
            types.append(AppState.verificationType.other)
        }
        AppState.setManualVerifyType(address: address, types: types)
        
        self.dismiss(animated: true)
    }
    
    func setLocalizedStrings() {
        screenshotLabel.text = "I took a screenshot"
        byHandLabel.text = "I copied it by hand"
        otherLabel.text = "I saved it another way"
        
        cancelButton.setTitle("Cancel", for: UIControl.State())
        verifyButton.setTitle("Verify Backup", for: UIControl.State())
        
        titleLabel.text = "You can manually back up your wallet by taking a screen shot of the QR key or copying down the text key. Please be sure it is saved in a very safe place. If you lose your key, your funds cannot be recovered."
    }
    
    func setThemedElements() {
        applyBottomSheetNavBarTheme(title: "Verify Backup")
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        screenshotLabel.theme_textColor = O3Theme.titleColorPicker
        byHandLabel.theme_textColor = O3Theme.titleColorPicker
        otherLabel.theme_textColor = O3Theme.titleColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
}
