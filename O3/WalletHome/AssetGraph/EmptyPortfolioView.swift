//
//  EmptyPortfolioView.swift
//  O3
//
//  Created by Andrei Terentiev on 10/23/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

protocol EmptyPortfolioDelegate: AnyObject {
    func emptyPortfolioRightButtonTapped()
    func buyNeoButtonTapped()
}

class EmptyPortfolioView: UIView {
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var leftActionButton: UIButton!
    @IBOutlet weak var rightActionButton: UIButton!
    @IBOutlet weak var dividerLine: UIView!
    
    
    weak var emptyDelegate: EmptyPortfolioDelegate?
    
    
    func setThemedElements() {
        emptyLabel.theme_textColor = O3Theme.lightTextColorPicker
        self.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        emptyDelegate?.buyNeoButtonTapped()
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
        emptyDelegate?.emptyPortfolioRightButtonTapped()
    }
}
