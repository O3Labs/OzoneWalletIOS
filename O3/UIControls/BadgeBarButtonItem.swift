//
//  BadgeBarButtonItem.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/20/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

public class BadgeBarButtonItem: UIBarButtonItem
{
    @IBInspectable
    public var badgeNumber: Int = 0 {
        didSet {
            self.updateBadge()
        }
    }
    
    private var label: UILabel?
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        self.updateBadge()
    }
    
    private func updateBadge()
    {
        if self.label == nil {
            let label = UILabel(frame: CGRect.zero)
            label.backgroundColor = .red
            label.alpha = 1.0
            label.layer.cornerRadius = 9
            label.clipsToBounds = true
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont(name: "Avenir-Medium", size: 12)
            label.layer.zPosition = 1
            self.label = label
            self.addObserver(self, forKeyPath: "view", options: [], context: nil)
        }
        guard let view = self.value(forKey: "view") as? UIView else { return }
        
        self.label?.text = "\(badgeNumber)"
        
        if self.badgeNumber > 0 && self.label?.superview == nil
        {
            view.addSubview(self.label!)
            
            self.label!.widthAnchor.constraint(equalToConstant: 18).isActive = true
            self.label!.heightAnchor.constraint(equalToConstant: 18).isActive = true
            self.label!.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 9).isActive = true
            self.label!.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -9).isActive = true
        }
        else if self.badgeNumber == 0 && self.label!.superview != nil
        {
            self.label!.removeFromSuperview()
        }
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "view")
    }
}
