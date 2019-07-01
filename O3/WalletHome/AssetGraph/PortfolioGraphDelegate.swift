//
//  PortfolioGraphDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 6/19/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import ScrollableGraphView

extension HomeViewController {
    @objc func updateGraphAppearance(_ sender: Any) {
        DispatchQueue.main.async {
            
            let needEmptyView = self.graphViewContainer.subviews.last ?? UIView() == self.emptyGraphView ?? UIView()
            
            self.graphView.removeFromSuperview()
            self.panView.removeFromSuperview()
            self.setupGraphView()
            self.getBalance()
            if needEmptyView {
                self.graphViewContainer.bringSubviewToFront(self.emptyGraphView!)
            }
        }
    }
    
    func setupGraphView() {
        graphView = ScrollableGraphView.ozoneTheme(frame: graphViewContainer.bounds, dataSource: self)
        graphViewContainer.embed(graphView)
        
        panView = GraphPanView(frame: graphViewContainer.bounds)
        panView.delegate = self
        graphViewContainer.embed(panView)
    }
    
    func panDataIndexUpdated(index: Int, timeLabel: UILabel) {
        DispatchQueue.main.async {
            self.selectedPrice = self.portfolio?.data.reversed()[index]
            self.walletHeaderCollectionView.reloadData()
            
            let posixString = self.portfolio?.data.reversed()[index].time ?? ""
            timeLabel.text = posixString.intervaledDateString(self.homeviewModel.selectedInterval)
            timeLabel.sizeToFit()
        }
    }
    
    func panEnded() {
        selectedPrice = self.portfolio?.data.first
        DispatchQueue.main.async { self.walletHeaderCollectionView.reloadData() }
    }
    
    func setEmptyGraphView() {
        if emptyGraphView == nil {
            emptyGraphView = EmptyPortfolioView(frame: graphViewContainer.bounds).loadNib()
            (emptyGraphView as! EmptyPortfolioView).emptyDelegate = self
            graphViewContainer.embed(emptyGraphView!)
            graphViewContainer.bringSubviewToFront(emptyGraphView!)
        }
        
        (emptyGraphView as! EmptyPortfolioView).emptyLabel.text = PortfolioStrings.emptyBalance
        (emptyGraphView as! EmptyPortfolioView).rightActionButton.setTitle(PortfolioStrings.depositTokens, for: UIControl.State())
        (emptyGraphView as! EmptyPortfolioView).leftActionButton.setTitle("Buy NEO", for: UIControl.State())
        (emptyGraphView as! EmptyPortfolioView).leftActionButton.isHidden = false
        (emptyGraphView as! EmptyPortfolioView).rightActionButton.isHidden = false
        (emptyGraphView as! EmptyPortfolioView).dividerLine.isHidden = false
        
        emptyGraphView?.isHidden = false
    }
    
    
    // MARK: - Graph delegate
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        if pointIndex > portfolio!.data.count {
            return 0
        }
        return homeviewModel?.referenceCurrency == .btc ? portfolio!.data.reversed()[pointIndex].averageBTC : portfolio!.data.reversed()[pointIndex].average
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return ""//String(format:"%@",portfolio!.data[pointIndex].time)
    }
    
    func numberOfPoints() -> Int {
        if portfolio == nil {
            return 0
        }
        return portfolio!.data.count
    }
}
