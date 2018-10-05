//
//  PrivateKeyCollectionViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol PrivateKeyCardDelegate: class {
   func backupTapped()
}

class PrivateKeyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var privateKeyImageView: UIImageView!
    @IBOutlet weak var backupButton: UIButton!

    weak var delegate: PrivateKeyCardDelegate?

    @IBAction func backupTapped(_ sender: Any) {
        delegate?.backupTapped()
    }

    var data: String? {
        didSet {
            backupButton.setTitle(OnboardingStrings.backupAndContinue, for: UIControl.State())

            self.privateKeyImageView.image = UIImage(qrData: data!, width: self.privateKeyImageView.frame.width, height: self.privateKeyImageView.frame.height, qrLogoName: "ic_QRkey")
            let attributedString = NSMutableAttributedString(string: data!)

            // *** Create instance of `NSMutableParagraphStyle`
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4 // Whatever line spacing you want in points
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.kern, value: NSNumber(value: 2.0), range: NSRange(location: 0, length: attributedString.length))
            self.privateKeyLabel.attributedText = attributedString
        }
    }
}
