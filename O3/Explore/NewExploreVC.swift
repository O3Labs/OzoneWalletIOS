//
//  NewExploreVC.swift
//  O3
//
//  Created by 吕益凯 on 2020/6/11.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit

class NewExploreVC: UIViewController {

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}
