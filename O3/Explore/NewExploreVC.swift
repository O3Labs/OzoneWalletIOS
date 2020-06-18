//
//  NewExploreVC.swift
//  O3
//
//  Created by 吕益凯 on 2020/6/11.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import FSPagerView
import JXSegmentedView


let kEmotionCellNumberOfOneRow = 4
let kEmotionCellRow = 2

class NewExploreVC: UIViewController,  UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, FSPagerViewDelegate, FSPagerViewDataSource{
    

    @IBOutlet weak var exploreTableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet weak var pagerView: FSPagerView!
//    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var buttonCollectionView: UICollectionView!
//    var pageControl :FSPageControl!
    @IBOutlet weak var buttonCollectionViewHeight: NSLayoutConstraint!
    
    let buttonCount : Int = 4
    
    lazy var pagerControl:FSPageControl = {
        let pageControl = FSPageControl(frame: self.pageView.frame)
        //设置下标的个数
        pageControl.numberOfPages = 2
        //设置下标位置
        pageControl.contentHorizontalAlignment = .center

        //设置下标指示器颜色（选中状态和普通状态）
        pageControl.setFillColor(UIColor(named: "pagerColor")!, for: .normal)
        pageControl.setFillColor(UIColor(named: "lightThemePrimary")!, for: .selected)
       
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)

        return pageControl

    }()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return 2
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
//        cell.imageView?.kf.
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        pagerView.dataSource = self
        
        self.pagerView.addSubview(pagerControl)
        self.pagerView.interitemSpacing = 8.0
        self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        self.pagerView.itemSize = FSPagerView.automaticSize
        
        if buttonCount > kEmotionCellNumberOfOneRow{
            buttonCollectionViewHeight.constant = 250.0
        }else{
            buttonCollectionViewHeight.constant = 130.0
        }
        exploreTableView.delegate = self
        exploreTableView.dataSource = self
        self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 200+buttonCollectionViewHeight.constant)
        self.exploreTableView.tableHeaderView = self.tableHeaderView
        
        exploreTableView.tableFooterView = UIView(frame: .zero)
        
        
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        buttonCollectionView.setCollectionViewLayout(LXFChatEmotionCollectionLayout(), animated: true)
        buttonCollectionView.bounces = false
        
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
        6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreHeaderButtonCollectionViewCell", for: indexPath) as! ExploreHeaderButtonCollectionViewCell
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
     // MARK:- FSPagerViewDelegate
       
       func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
           pagerControl.currentPage = targetIndex
       }
    
}




class LXFChatEmotionCollectionLayout: UICollectionViewFlowLayout {
    // 保存所有item
    fileprivate var attributesArr: [UICollectionViewLayoutAttributes] = []
    
    // MARK:- 重新布局
    override func prepare() {
        super.prepare()
        
        let itemW: CGFloat = UIScreen.main.bounds.size.width / CGFloat(kEmotionCellNumberOfOneRow)
        let itemH: CGFloat = 120.0
        // 设置itemSize
        itemSize = CGSize(width: itemW, height: itemH)
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
        
        // 设置collectionView属性
        collectionView?.isPagingEnabled = true
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = true
        let insertMargin = (collectionView!.bounds.height - 2 * itemH) * 0.5
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        
        var page = 0
        let itemsCount = collectionView?.numberOfItems(inSection: 0) ?? 0
        for itemIndex in 0..<itemsCount {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            page = itemIndex / (kEmotionCellNumberOfOneRow * kEmotionCellRow)
            // 通过一系列计算, 得到x, y值
            let x = itemSize.width * CGFloat(itemIndex % Int(kEmotionCellNumberOfOneRow)) + (CGFloat(page) * UIScreen.main.bounds.size.width)
            let y = itemSize.height * CGFloat((itemIndex - page * kEmotionCellRow * kEmotionCellNumberOfOneRow) / kEmotionCellNumberOfOneRow)
//            print("第\(indexPath.row) x:\(x) y:\(y)")
            attributes.frame = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
            // 把每一个新的属性保存起来
            attributesArr.append(attributes)
        }
        
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var rectAttributes: [UICollectionViewLayoutAttributes] = []
        _ = attributesArr.map({
            if rect.contains($0.frame) {
                rectAttributes.append($0)
            }
        })
        return rectAttributes
    }
    override open var collectionViewContentSize: CGSize {
        var page = 0
        let itemsCount = collectionView?.numberOfItems(inSection: 0) ?? 0
        if itemsCount == 0{
            return CGSize(width: collectionView!.bounds.width, height: collectionView!.bounds.height);
        }
        page = (itemsCount-1) / (kEmotionCellNumberOfOneRow * kEmotionCellRow)
        return CGSize(width: (collectionView!.bounds.width) * CGFloat(page+1), height: collectionView!.bounds.height);
    }
    
}
extension NewExploreVC: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
    
    func listDidAppear() {
            //因为`JXSegmentedListContainerView`内部通过`UICollectionView`的cell加载列表。当切换tab的时候，之前的列表所在的cell就被回收到缓存池，就会从视图层级树里面被剔除掉，即没有显示出来且不在视图层级里面。这个时候MJRefreshHeader所持有的UIActivityIndicatorView就会被设置hidden。所以需要在列表显示的时候，且isRefreshing==YES的时候，再让UIActivityIndicatorView重新开启动画。
    //        if (self.tableView.mj_header.isRefreshing) {
    //            UIActivityIndicatorView *activity = [self.tableView.mj_header valueForKey:@"loadingView"];
    //            [activity startAnimating];
    //        }

    //        print("listDidAppear")
        }

        func listDidDisappear() {
    //        print("listDidDisappear")
        }
}
