//
//  PriceInputToggleToolbar.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
protocol PriceInputToggleToolbarDelegate {
    func toggleInput(manually: Bool)
}
class PriceInputToggleToolbar: UIView {
    
    private var inputManually: Bool! = false
    
    //MARK: - view setup
    var view: UIView! {
        didSet {
            view.theme_backgroundColor = O3Theme.backgroundColorPicker
        }
    }
    
    func setup() {
        xibSetup()
        DispatchQueue.main.async {
            self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib() {
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        super.awakeFromNib()
    }
    
    //MARK: -
    var delegate: PriceInputToggleToolbarDelegate? {
        didSet {
            DispatchQueue.main.async {
                self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
            }
        }
    }
    
    //MARK: -
    @IBAction func toggleTapped(_ sender: UIButton) {
        inputManually = !inputManually
        sender.isSelected = inputManually
        delegate?.toggleInput(manually: inputManually!)
    }
    
}

private extension PriceInputToggleToolbar {
    
    func xibSetup() {
        backgroundColor = UIColor.clear
        view = loadNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Adding custom subview on top of our view
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
    }
}
