//
//  TutorialCardCollectionViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 6/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol TutorialCardDelegate: class {
    func backTapped()
    func forwardTapped()
}

class TutorialCardCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardInfoOneLabel: UILabel!
    @IBOutlet weak var cardInfoTwoLabel: UILabel!
    @IBOutlet weak var cardEmphasisLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!

    weak var delegate: TutorialCardDelegate?

    struct TutorialCardData {
        var title: String
        var infoOne: String
        var infoTwo: String?
        var emphasis: String?
    }

    var data: TutorialCardData? {
        didSet {
            backButton.setTitle(OnboardingStrings.back, for: UIControlState())
            forwardButton.setTitle(OnboardingStrings.continueButton, for: UIControlState())

            cardTitleLabel.text = data?.title ?? ""
            cardInfoOneLabel.text = data?.infoOne ?? ""
            cardInfoTwoLabel.text = data?.infoTwo ?? ""
            cardEmphasisLabel.text = data?.emphasis ?? ""
        }
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        delegate?.backTapped()
    }

    @IBAction func forwardButtonTapped(_ sender: Any) {
        delegate?.forwardTapped()
    }
}
