//
//  BuyNeoTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 5/17/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class BuyNeoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var buyNeoButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    override func layoutSubviews() {
        buyNeoButton.setTitle("Buy NEO Today!", for: UIControl.State())
        let gradientBuy = CAGradientLayer()
        gradientBuy.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: buyNeoButton.bounds.height)
        gradientBuy.colors = [
            UIColor(red:0.57, green:0.88, blue:0, alpha:1).cgColor,
            UIColor(red:0.35, green:0.75, blue:0, alpha:1).cgColor]
        gradientBuy.locations = [0, 1]
        gradientBuy.startPoint = CGPoint(x: 1.0, y: 0.5)
        gradientBuy.endPoint = CGPoint(x: 0.5, y: 1)
        gradientBuy.cornerRadius = buyNeoButton.cornerRadius
        buyNeoButton.layer.insertSublayer(gradientBuy, at: 0)
        setNeedsDisplay()
        super.layoutSubviews()  
    }
    
    
    @IBAction func tappedBuyNEO(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let buyWithFiat = UIAlertAction(title: "With Fiat", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://buy.o3.network/?a=" + (Authenticated.wallet?.address)!)!)
//            RevenueEvent.shared.buyInitiated(buyWith: "fiat", source: "portfolio")
        }
        actionSheet.addAction(buyWithFiat)
        
        let buyWithCrypto = UIAlertAction(title: "With Crypto", style: .default) { _ in
            Controller().openDappBrowserV2(url: URL(string: "https://swap.o3.app")!)
//            RevenueEvent.shared.buyInitiated(buyWith: "crypto", source: "portfolio")
        }
        actionSheet.addAction(buyWithCrypto)
        
        let cancel = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { _ in
            
        }
        actionSheet.addAction(cancel)
        actionSheet.popoverPresentationController?.sourceView = sender as? UIView
        UIApplication.shared.keyWindow?.rootViewController?.present(actionSheet, animated: true, completion: nil)
    }
    
}
