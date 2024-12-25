//
//  InsightsRangeViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019 spelist. All rights reserved.
//

import UIKit
import FSCalendar

class InsightsRangeViewController: TKBaseViewController {

    private var navigationBar: TKNormalNavigationBar!
    private var calendarView: FSCalendar!
}

extension InsightsRangeViewController {
    override func initView() {
        self.view.backgroundColor = ColorUtil.backgroundColor
        self.enablePanToDismiss()
        
        initNavigationBar()
    }
    
    private func initNavigationBar() {
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Range", target: self)
        self.addSubview(view: navigationBar) { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }
    }
    
    private func initCalendar() {
        
    }
}
