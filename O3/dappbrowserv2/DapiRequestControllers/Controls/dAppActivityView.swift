//
//  dAppActivityView.swift
//  O3
//
//  Created by Apisit Toompakdee on 12/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Lottie

class dAppActivityView: UIView {

    @IBOutlet var iconContainerView: UIView!
    @IBOutlet var titleLabel: UILabel!
    
    let loadingView = LOTAnimationView(name: "loader_portfolio")
    let successView = LOTAnimationView(name: "claim_success")
    
    var view: UIView! {
        didSet {
            view.theme_backgroundColor = O3Theme.backgroundColorPicker
            loadingView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            successView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            iconContainerView.addSubview(loadingView)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    func beginLoading() {
        loadingView.play()
        titleLabel.text = String(format: "Processing")
        titleLabel.theme_textColor = O3Theme.primaryColorPicker
    }
    
    func success() {
        loadingView.removeFromSuperview()
        iconContainerView.addSubview(successView)
        successView.animationProgress = 0.2 //skip the loading in the front
        successView.play()
        titleLabel.text = String(format: "Transaction sent")
        titleLabel.theme_textColor = O3Theme.positiveGainColorPicker
    }
    
    func setup() {
        xibSetup()
        DispatchQueue.main.async {
            self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }


}


private extension dAppActivityView {
    
    func xibSetup() {
        backgroundColor = UIColor.clear
        view = loadNib()
        view.frame = bounds
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
