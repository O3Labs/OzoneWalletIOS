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
    func originalPriceSelected(value: Double)
    func topPriceSelected(value: Double)
    func doneTapped()
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
    @IBOutlet var currentMedianPriceButton: UIButton!
    @IBOutlet var topPriceButton: UIButton!
    
    private var originalPriceSet: Bool = false
    var step: Double? = 1 // default step for the stepper
    
    var currentPercent: Double! = 0 //..., -2, -1, 0, 1, 2, 3,...
    
    var topOrderPrice: Double? {
        didSet{
            topPriceButton.setTitle(topOrderPrice?.formattedStringWithoutSeparator(8, removeTrailing: true), for: .normal)
        }
    }
    
    var value: Double? {
        didSet {
            if originalPriceSet == true {
                return
            }
            originalPriceSet = true
            currentMedianPriceButton.setTitle(value?.formattedStringWithoutSeparator(8, removeTrailing: true), for: .normal)
        }
    }
    var delegate: PriceInputToolbarDelegate?
    
    deinit {
        
    }
    
    //MARK: -
    @IBAction func plusTapped(_ sender: Any) {
        currentPercent = currentPercent + 1
        let calculated = value! + (value! * currentPercent / 100)
        delegate?.stepper(value: calculated, percent: currentPercent)
    }
    @IBAction func minusTapped(_ sender: Any) {
        currentPercent = currentPercent - 1
        let calculated = value! + (value! * currentPercent / 100)
        delegate?.stepper(value: calculated, percent: currentPercent)
    }
    
    @IBAction func currentPriceTapped(_ sender: Any) {
        currentPercent = 0
        delegate?.originalPriceSelected(value: value!)
    }
    
    @IBAction func topPriceTapped(_ sender: Any) {
        currentPercent = 0
        delegate?.topPriceSelected(value: topOrderPrice!)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        delegate?.doneTapped()
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
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
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
