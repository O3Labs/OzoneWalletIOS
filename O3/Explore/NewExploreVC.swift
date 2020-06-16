//
//  NewExploreVC.swift
//  O3
//
//  Created by 吕益凯 on 2020/6/11.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
//import FSPagerView

class NewExploreVC: UIViewController,  UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    

    @IBOutlet weak var exploreTableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
//    @IBOutlet weak var pagerView: FSPagerView!
//        {
//        didSet {
//            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
//            self.pagerView.itemSize = FSPagerView.automaticSize
//        }
//    }
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
//    func numberOfItems(in pagerView: FSPagerView) -> Int {
//        0
//    }
//
//    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
//        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
//
//        return cell
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        pagerView.delegate = self
//        pagerView.dataSource = self
        
        exploreTableView.delegate = self
        exploreTableView.dataSource = self
        self.exploreTableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height * 0.45)
        exploreTableView.tableFooterView = UIView(frame: .zero)
        
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewExploreTableViewCell") as! NewExploreTableViewCell
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreHeaderButtonCollectionViewCell", for: indexPath) as! ExploreHeaderButtonCollectionViewCell
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (UIScreen.main.bounds.size.width - 40)/5
        return CGSize(width:CGFloat(itemWidth), height: 115)
    }
    
    
    

}
