//
//  NewExploreSegmentViewController.swift
//  O3
//
//  Created by jcc on 2020/6/18.
//  Copyright © 2020 O3 Labs Inc. All rights reserved.
//

import UIKit
import JXSegmentedView

class NewExploreSegmentViewController: UIViewController {
    var segmentedDataSource: JXSegmentedBaseDataSource?
    let segmentedView = JXSegmentedView()
    lazy var listContainerView: JXSegmentedListContainerView! = {
        return JXSegmentedListContainerView(dataSource: self)
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titles = ["推荐", "娱乐", "金融"]
        let dataSource = JXSegmentedTitleDataSource()
        dataSource.isTitleColorGradientEnabled = true
        dataSource.titles = titles
        segmentedDataSource = dataSource
        //segmentedViewDataSource一定要通过属性强持有！！！！！！！！！
        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self
        view.addSubview(segmentedView)
        
        segmentedView.listContainer = listContainerView
        view.addSubview(listContainerView)
        
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorWidth = 20
        segmentedView.indicators = [indicator]
        view.addSubview(indicator)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)

           //处于第一个item的时候，才允许屏幕边缘手势返回
           navigationController?.interactivePopGestureRecognizer?.isEnabled = (segmentedView.selectedIndex == 0)
       }

       override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)

           //离开页面的时候，需要恢复屏幕边缘手势，不能影响其他页面
           navigationController?.interactivePopGestureRecognizer?.isEnabled = true
       }
       
       override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()

           segmentedView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 50)
        
        listContainerView.frame = CGRect(x: 0, y: segmentedView.frame.maxY, width: view.bounds.size.width, height: view.bounds.size.height - segmentedView.frame.maxY)
       }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension NewExploreSegmentViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        if let dotDataSource = segmentedDataSource as? JXSegmentedDotDataSource {
            //先更新数据源的数据
            dotDataSource.dotStates[index] = false
            //再调用reloadItem(at: index)
            segmentedView.reloadItem(at: index)
        }

        navigationController?.interactivePopGestureRecognizer?.isEnabled = (segmentedView.selectedIndex == 0)
    }
}

extension NewExploreSegmentViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        if let titleDataSource = segmentedView.dataSource as? JXSegmentedBaseDataSource {
            return titleDataSource.dataSource.count
        }
        return 0
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewExploreVC") as! NewExploreVC

        return vc
//        let vc = LoadDataListViewController()
//        vc.typeString = segmentedDataSource.titles[index]
//        return vc
    }
}
