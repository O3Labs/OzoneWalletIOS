//
//  NewHomeVC.swift
//  O3
//
//  Created by 吕益凯 on 2020/6/11.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import JXSegmentedView

extension JXPagingListContainerView: JXSegmentedViewListContainer {}


class NewHomeVC: UIViewController {
    @IBOutlet weak var walletNameSelectButton: UIButton!
    @IBOutlet weak var walletNameSelectLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var keyButton: UIButton!
    
    @IBOutlet weak var totalNumberLabel: UILabel!
    @IBOutlet weak var watchButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var sendAndReceiveBgView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    
    lazy var pagingView: JXPagingView = preferredPagingView()
    lazy var userHeaderView: PagingViewTableHeaderView = preferredTableHeaderView()
    let dataSource: JXSegmentedTitleDataSource = JXSegmentedTitleDataSource()
    lazy var segmentedView: JXSegmentedView = JXSegmentedView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat(headerInSectionHeight)))
    var titles = ["Token", "Collection"]
    var tableHeaderViewHeight: Int = 200
    var headerInSectionHeight: Int = 50
    var isNeedHeader = false
    var isNeedFooter = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false

        dataSource.titles = titles
        dataSource.titleSelectedColor = UIColor(red: 105/255, green: 144/255, blue: 239/255, alpha: 1)
        dataSource.titleNormalColor = UIColor.black
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.isTitleZoomEnabled = true

        segmentedView.backgroundColor = UIColor.white
        segmentedView.delegate = self
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        segmentedView.dataSource = dataSource

        let lineView = JXSegmentedIndicatorLineView()
        lineView.indicatorColor = UIColor(red: 105/255, green: 144/255, blue: 239/255, alpha: 1)
        lineView.indicatorWidth = 30
        segmentedView.indicators = [lineView]

        let lineWidth = 1/UIScreen.main.scale
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.lightGray
        bottomLineView.frame = CGRect(x: 0, y: segmentedView.bounds.height - lineWidth, width: segmentedView.bounds.width, height: lineWidth)
        bottomLineView.autoresizingMask = .flexibleWidth
        segmentedView.addSubview(bottomLineView)

        pagingView.mainTableView.gestureDelegate = self
        self.contentView.addSubview(pagingView)
        
        segmentedView.listContainer = pagingView.listContainerView

        //扣边返回处理，下面的代码要加上
        pagingView.listContainerView.scrollView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
        pagingView.mainTableView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
        
        
        sendAndReceiveBgView.layer.shadowRadius = 25
        sendAndReceiveBgView.layer.shadowOffset = CGSize(width: 0, height: 10)
        sendAndReceiveBgView.layer.shadowColor = UIColor(red: 0.71, green: 0.81, blue: 1, alpha: 0.2).cgColor
        
        // Create action listener
        walletNameSelectButton.addTarget(self, action: #selector(showMultiWalletDisplay), for: .touchUpInside)
        
    }
    @objc func showMultiWalletDisplay() {
        Controller().openPortfolioSelector()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = (segmentedView.selectedIndex == 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pagingView.frame = self.contentView.bounds
    }
    func preferredTableHeaderView() -> PagingViewTableHeaderView {
        let FYactiveHeadView = Bundle.main.loadNibNamed("PagingViewTableHeaderView", owner: nil, options: nil)?.last as! PagingViewTableHeaderView
        return FYactiveHeadView
    }
    func preferredPagingView() -> JXPagingView {
        return JXPagingView(delegate: self)
    }
        // Do any additional setup after loading the view.

}

extension NewHomeVC: JXPagingViewDelegate {

    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        return tableHeaderViewHeight
    }

    func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        return userHeaderView
    }

    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        return headerInSectionHeight
    }

    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        return segmentedView
    }

    func numberOfLists(in pagingView: JXPagingView) -> Int {
        return titles.count
    }

    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        let list = ListViewController()
        list.title = titles[index]
        list.isNeedHeader = isNeedHeader
        list.isNeedFooter = isNeedFooter
        if index == 0 {
            list.dataSource = ["橡胶火箭", "橡胶火箭炮", "橡胶机关枪", "橡胶子弹", "橡胶攻城炮", "橡胶象枪", "橡胶象枪乱打", "橡胶灰熊铳", "橡胶雷神象枪", "橡胶猿王枪", "橡胶犀·榴弹炮", "橡胶大蛇炮", "橡胶火箭", "橡胶火箭炮", "橡胶机关枪", "橡胶子弹", "橡胶攻城炮", "橡胶象枪", "橡胶象枪乱打", "橡胶灰熊铳", "橡胶雷神象枪", "橡胶猿王枪", "橡胶犀·榴弹炮", "橡胶大蛇炮"]
        }else if index == 1 {
            list.dataSource = ["吃烤肉", "吃鸡腿肉", "吃牛肉", "各种肉"]
        }else {
            list.dataSource = ["【剑士】罗罗诺亚·索隆", "【航海士】娜美", "【狙击手】乌索普", "【厨师】香吉士", "【船医】托尼托尼·乔巴", "【船匠】 弗兰奇", "【音乐家】布鲁克", "【考古学家】妮可·罗宾"]
        }
        return list
    }
}

extension NewHomeVC: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = (index == 0)
    }
}

extension NewHomeVC: JXPagingMainTableViewGestureDelegate {
    func mainTableViewGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        //禁止segmentedView左右滑动的时候，上下和左右都可以滚动
        if otherGestureRecognizer == segmentedView.collectionView.panGestureRecognizer {
            return false
        }
        return gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) && otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
    }
}
