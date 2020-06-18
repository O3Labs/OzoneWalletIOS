//
//  ListViewController.swift
//  JXPagingViewExample
//
//  Created by jiaxin on 2019/12/30.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    lazy var tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    var dataSource: [String] = [String]()
    var isNeedHeader = false
    var isNeedFooter = false
    var listViewDidScrollCallback: ((UIScrollView) -> ())?
    var isHeaderRefreshed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor.white
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib.init(nibName: "CurrencyTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "CurrencyTableViewCell")
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        //列表的contentInsetAdjustmentBehavior失效，需要自己设置底部inset
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIApplication.shared.keyWindow!.jx_layoutInsets().bottom, right: 0)
        view.addSubview(tableView)
    
        beginFirstRefresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    func beginFirstRefresh() {
        if !isHeaderRefreshed {
            if (self.isNeedHeader) {
            }else {
                self.isHeaderRefreshed = true
                self.tableView.reloadData()
            }
        }
    }

    @objc func headerRefresh() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            self.isHeaderRefreshed = true
            self.tableView.reloadData()
        }
    }

    @objc func loadMore() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            self.dataSource.append("加载更多成功")
            self.tableView.reloadData()
        }
    }
}

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isHeaderRefreshed {
            return dataSource.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        cell.textLabel?.text = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyTableViewCell", for: indexPath) as! CurrencyTableViewCell

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.listViewDidScrollCallback?(scrollView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

extension ListViewController: JXPagingViewListViewDelegate {
    func listView() -> UIView {
        return view
    }

    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        self.listViewDidScrollCallback = callback
    }

    func listScrollView() -> UIScrollView {
        return self.tableView
    }

    func listWillAppear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listDidAppear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listWillDisappear() {
        print("\(self.title ?? ""):\(#function)")
    }

    func listDidDisappear() {
        print("\(self.title ?? ""):\(#function)")
    }
}
