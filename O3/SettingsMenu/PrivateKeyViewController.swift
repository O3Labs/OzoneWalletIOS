//
//  PrivateKeyViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/30/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit

class PrivateKeyViewController: UIViewController {
    @IBOutlet weak var qrView: UIImageView!
    @IBOutlet weak var privateKeyLabel: UILabel!

    var privateKey: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBottomSheetNavBarTheme(title: "Private Key")
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
        privateKeyLabel.text = privateKey
        qrView.image = UIImage(qrData: privateKey, width: qrView.frame.width, height: qrView.frame.height, qrLogoName: "ic_QRkey")
    }

    @IBAction func shareTapped(_ sender: Any) {
        let string = privateKeyLabel.text!
        let activityViewController = UIActivityViewController(activityItems: [string], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
}
