//
//  PriceInputToolbar.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/24/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

protocol PriceInputToolbarDelegate {
    func stepper(value: Double, percent: Double)
    func defaultValueTapped(value: Double)
}

class PriceInputToolbar:  UIView {
    
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
    
    //MARK: -
    @IBOutlet var stepper: UIStepper!
    
    var step: Double? = 1 // default step for the stepper
    var currentPercent: Double! = 0 //..., -2, -1, 0, 1, 2, 3,...
    var value: Double?
    var delegate: PriceInputToolbarDelegate?
    
    //MARK: -
    @IBAction func stepperTapped(_ sender: Any) {
        let calculated = value! + (value! * stepper.value / 100)
        currentPercent = stepper.value
        delegate?.stepper(value: calculated, percent: stepper.value)
    }
}

private extension PriceInputToolbar {
    
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
