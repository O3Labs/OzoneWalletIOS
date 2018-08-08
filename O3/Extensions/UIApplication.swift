//
//  UIApplication.swift
//  O3
//
//  Created by Andrei Terentiev on 9/28/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit

extension UIApplication {
    //swiftlint:disable force_cast
    static var appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
   
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
}


