//
//  BadgeUIButton.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/26/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit

class BadgeUIButton : UIButton {
    
    var badgeValue : String! = "" {
        didSet {
            self.layoutSubviews()
        }
    }
    
    override init(frame :CGRect)  {
        // Initialize the UIView
        super.init(frame : frame)
        
        self.awakeFromNib()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.awakeFromNib()
    }
    
    
    override func awakeFromNib()
    {
        self.drawBadgeLayer()
    }
    
    var badgeLayer :CAShapeLayer!
    func drawBadgeLayer() {
        
        if self.badgeLayer != nil {
            self.badgeLayer.removeFromSuperlayer()
        }
        
        // Omit layer if text is nil
        if self.badgeValue == nil || self.badgeValue.count == 0 {
            return
        }
        
        //! Initial label text layer
        let labelText = CATextLayer()
        labelText.contentsScale = UIScreen.main.scale
        labelText.string = self.badgeValue.uppercased()
        labelText.fontSize = 12.0
        labelText.font = UIFont(name: "Avenir-Heavy", size: 12)
        labelText.alignmentMode = kCAAlignmentCenter
        labelText.foregroundColor = UIColor.white.cgColor
        let labelString = self.badgeValue.uppercased() as String?
        let labelFont = UIFont(name: "Avenir-Heavy", size: 12)
        let attributes = [kCTFontAttributeName : labelFont]
        let w = CGFloat(18.0)
        let h = CGFloat(18.0)  // fixed height
        let labelWidth = min(w * 0.8, h)    // Starting point
        let rect = labelString!.boundingRect(with: CGSize(width: labelWidth, height: h), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes as [NSAttributedStringKey : Any], context: nil)
        let textWidth = round(rect.width * UIScreen.main.scale)
        labelText.frame = CGRect(x: 0, y: 0.5, width: w, height: h)
        
        //! Initialize outline, set frame and color
        let shapeLayer = CAShapeLayer()
        shapeLayer.contentsScale = UIScreen.main.scale
        let frame : CGRect = CGRect(x: 0, y: 0, width: w, height: h)
        let cornerRadius = CGFloat(w/2.0)
        let borderInset = CGFloat(-1.0)
        let aPath = UIBezierPath(roundedRect: frame.insetBy(dx: borderInset, dy: borderInset), cornerRadius: cornerRadius)
        
        shapeLayer.path = aPath.cgPath
        shapeLayer.fillColor = UIColor.red.cgColor
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 0.5
        
        shapeLayer.insertSublayer(labelText, at: 0)
        
        shapeLayer.frame = shapeLayer.frame.offsetBy(dx: w / 2.0, dy: 0)
        
        self.layer.insertSublayer(shapeLayer, at: 999)
        self.layer.masksToBounds = false
        self.badgeLayer = shapeLayer
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.drawBadgeLayer()
        self.setNeedsDisplay()
    }
    
}
