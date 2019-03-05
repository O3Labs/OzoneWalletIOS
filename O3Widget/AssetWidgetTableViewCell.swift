//
//  AssetWidgetTableViewCell.swift
//  O3Widget
//
//  Created by Apisit Toompakdee on 3/5/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import UIKit
public struct WidgetAsset {
    public var name: String!
    public var formattedPrice: String!
}

public typealias JSONDictionary = [String:  Any]

class AssetWidgetTableViewCell: UITableViewCell {
    
    @IBOutlet var assetImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var priceLabel: UILabel?
    
    var userCurrency: String {
        let stringValue = UserDefaults.standard.string(forKey: "referenceCurrencyKey")
        if stringValue == nil {
            return "usd"
        }
        return stringValue!
    }
    
    var asset: WidgetAsset! {
        didSet{
            self.nameLabel?.text = asset.name
            let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", asset.name.uppercased())
            self.assetImageView?.downloadedFrom(link: imageURL)
            self.loadPricing(assetSymbol: asset.name, currency: userCurrency)
        }
    }
    
    func loadPricing(assetSymbol: String, currency: String) {
        let postData = NSData(data: "".data(using: String.Encoding.utf8)!)
        let urlString = String(format: "https://platform.o3.network/api/v1/pricing/%@/%@", assetSymbol, currency)
        
        let request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary else {
                return
            }
            let decoder = JSONDecoder()
            guard let dictionary = json?["result"] as? JSONDictionary,
                let data = try? JSONSerialization.data(withJSONObject: dictionary["data"] as Any, options: .prettyPrinted),
                let decoded = try? decoder.decode(WidgetAssetPrice.self, from: data) else {
                    return
            }
            let fm = NumberFormatter()
            fm.locale = Locale(identifier: "en_US")
            fm.numberStyle = .currency
            fm.minimumFractionDigits = 2
            fm.maximumFractionDigits = 2
            DispatchQueue.main.async {
                self.priceLabel?.text = fm.string(from: NSNumber(value: decoded.price))
            }
        })
        
        dataTask.resume()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
