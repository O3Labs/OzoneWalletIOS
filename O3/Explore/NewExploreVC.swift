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
import SwiftTheme


let kEmotionCellNumberOfOneRow = 4
let kEmotionCellRow = 2

class NewExploreVC: UIViewController,  UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, FSPagerViewDelegate, FSPagerViewDataSource{
    var typeString: String = ""

    enum tabName: String {
        case Recommend = "Recommend"
        case Entertainment = "Entertainment"
        case Token = " Token "
    }
    
    @IBOutlet weak var exploreTableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet weak var pagerView: FSPagerView!
//    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var buttonCollectionView: UICollectionView!
//    var pageControl :FSPageControl!
    @IBOutlet weak var buttonCollectionViewHeight: NSLayoutConstraint!
    
    var bannerFeatureFeedData: FeatureFeed?
    var bannerNewsfeedData: FeedData?
    var dappsData = [Dapps]()
    var exploreAssetsData = [ExploreAssets]()
    
    lazy var pagerControl:FSPageControl = {
        let pageControl = FSPageControl(frame: CGRect.init(x: 0, y: 0, width: self.pageView.frame.size.width, height: self.pageView.frame.size.height))
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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.typeString == tabName.Recommend.rawValue {
            loadFeatureFeed()
            loadDapps()
            
        }else if self.typeString == tabName.Entertainment.rawValue{
            loadNewsFeed()
            loadDapps()
        }
        loadAssets()
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        if self.typeString == tabName.Recommend.rawValue {
            return self.bannerFeatureFeedData?.features.count ?? 0
        }else if self.typeString == tabName.Entertainment.rawValue{
            if bannerNewsfeedData?.items.count ?? 0 >= 4{
                return 4
            }else{
                return self.bannerNewsfeedData?.items.count ?? 0
            }
        }else{
            return 0
        }
    }

    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        if self.typeString == tabName.Recommend.rawValue {
            let item = self.bannerFeatureFeedData?.features[index]
            cell.imageView?.kf.setImage(with: URL(string: item?.imageURL ?? ""))
        }else if self.typeString == tabName.Entertainment.rawValue{
            let item = self.bannerNewsfeedData?.items[index]
            if item?.images.count ?? 0 > 0{
                cell.imageView?.kf.setImage(with: URL(string: item?.images.first?.url ?? ""))
            }
        }
        
        return cell
    }
    
    public func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if self.typeString == tabName.Recommend.rawValue {
            let item = self.bannerFeatureFeedData?.features[index]
            Controller().openDappBrowserV2(url: URL(string: item?.actionURL ?? "")!)
        }else if self.typeString == tabName.Entertainment.rawValue{
            let item = self.bannerNewsfeedData?.items[index]
            Controller().openDappBrowserV2(url: URL(string: item?.link ?? "")!)
        }

    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        pagerView.delegate = self
        pagerView.dataSource = self
        
        self.pageView.addSubview(pagerControl)
        self.pagerView.interitemSpacing = 8.0
        self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        self.pagerView.itemSize = FSPagerView.automaticSize
        
        if dappsData.count > kEmotionCellNumberOfOneRow{
            buttonCollectionViewHeight.constant = 250.0
        }else{
            buttonCollectionViewHeight.constant = 130.0
        }

        exploreTableView.delegate = self
        exploreTableView.dataSource = self
        self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 200+buttonCollectionViewHeight.constant)
        if typeString == tabName.Recommend.rawValue{
            self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 200+buttonCollectionViewHeight.constant)
        }else if typeString == tabName.Entertainment.rawValue{
            self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 200)
            self.buttonCollectionView.isHidden = true
        }else {
            self.tableHeaderView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            self.buttonCollectionView.isHidden = true
        }
        self.exploreTableView.tableHeaderView = self.tableHeaderView
        
        exploreTableView.tableFooterView = UIView(frame: .zero)
        exploreTableView.theme_backgroundColor = O3Theme.backgroundColorPicker

        
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        buttonCollectionView.setCollectionViewLayout(LXFChatEmotionCollectionLayout(), animated: true)
        buttonCollectionView.bounces = false
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.typeString == tabName.Entertainment.rawValue{
            return self.dappsData.count
        }else{
            return self.exploreAssetsData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewExploreTableViewCell") as! NewExploreTableViewCell
        
        if self.typeString == tabName.Entertainment.rawValue{
            let item = self.dappsData[indexPath.row]
            cell.exploreImageView.kf.setImage(with: URL(string: item.iconURL))
            cell.exploreTitleLabel.text = item.name
            cell.exploreDetailLabel?.text = item.description
        }else{
            let item = self.exploreAssetsData[indexPath.row]
            cell.exploreImageView.kf.setImage(with: URL(string: item.logoURL))
            cell.exploreTitleLabel.text = item.symbol
            cell.exploreDetailLabel?.text = item.symbol
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if  self.typeString == tabName.Entertainment.rawValue {
            let item = self.dappsData[indexPath.row]
            Controller().openDappBrowserV2(url: URL(string: item.url)!)
        }else{
            let item = self.exploreAssetsData[indexPath.row]
            Controller().openDappBrowserV2(url: URL(string: item.webURL)!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dappsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExploreHeaderButtonCollectionViewCell", for: indexPath) as! ExploreHeaderButtonCollectionViewCell
        let item = self.dappsData[indexPath.row]
        cell.buttonImageView?.kf.setImage(with: URL(string: item.iconURL ))
        if item.name == "O3 Fiat Gateway"{
            cell.buttonTitleLabel.text = "O3 Fiat"
        }else{
            cell.buttonTitleLabel.text = item.name
        }
        cell.buttonTitleLabel.theme_textColor = O3Theme.titleColorPicker
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.dappsData[indexPath.row]
        Controller().openDappBrowserV2(url: URL(string: item.url )!)
    }
    
     // MARK:- FSPagerViewDelegate
       
    func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
        pagerControl.currentPage = targetIndex
    }
    // MARK:- 网络请求
    //第一个banner
    func loadFeatureFeed(){
        O3Client().getFeatures() { result in
            switch result {
            case .failure:
                return
            case .success(let FeatureFeed):
                DispatchQueue.main.async {
                    self.bannerFeatureFeedData = FeatureFeed
                    self.pagerControl.numberOfPages = FeatureFeed.features.count
                    self.pagerView.reloadData()
                }
            }
        }
    }
    //第二个banner
    func loadNewsFeed(){
        O3Client().getNewsFeed() { result in
            switch result {
            case .failure:
                return
            case .success(let feedData):
                DispatchQueue.main.async {
                    self.bannerNewsfeedData = feedData
                    if feedData.items.count >= 4{
                        self.pagerControl.numberOfPages = 4
                    }else{
                        self.pagerControl.numberOfPages = feedData.items.count
                    }
                    self.pagerView.reloadData()
                }
            }
        }
    }
    //获取dapps
    func loadDapps(){
        O3Client().getDapps(){ result in
            switch result {
            case .failure:
                return
            case .success(let dappsList):
                DispatchQueue.main.async {
                    self.dappsData.removeAll()
                    if self.typeString == tabName.Recommend.rawValue{
                        for dapp in dappsList{
                            if dapp.name == "O3 Fiat Gateway" || dapp.name == "O3 Swap" || dapp.name == "Staketology"{
                                self.dappsData.append(dapp)
                            }
                        }
                    }else{
                        self.dappsData = dappsList
                    }
                    self.buttonCollectionView.reloadData()
                }
            }
        }
    }
    //获取assets
    func loadAssets(){
        O3Client().getExploreAssets(){ result in
            switch result {
            case .failure:
                return
            case .success(let assetsList):
                DispatchQueue.main.async {
                    self.exploreAssetsData.removeAll()
                    if self.typeString == tabName.Recommend.rawValue{
                        for assets in assetsList{
                            if assets.symbol == "NEO" || assets.symbol == "GAS" || assets.symbol == "ONT" || assets.symbol == "ONG"{
                                self.exploreAssetsData.append(assets)
                            }
                        }
                    }else{
                        self.exploreAssetsData = assetsList
                    }
                    self.exploreAssetsData = self.exploreAssetsData.filterDuplicates({$0.symbol})
                    self.exploreTableView.reloadData()
                }
            }
        }
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
extension Array {
    
    // 去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}
