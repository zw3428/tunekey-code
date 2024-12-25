//
//  SLessonPreparationDetailsController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/25.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class SLessonPreparationDetailsController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    
    private lazy var titles = ["Practice", "Homework"]
    private lazy var titleMap = [String: TKBaseViewController]()
    private lazy var pageViewManager: PageViewManager = {
        // 创建DNSPageStyle，设置样式
        let style = PageStyle()
        style.isShowBottomLine = true
        style.isTitleViewScrollEnabled = false
        style.titleViewBackgroundColor = UIColor.clear
        style.titleColor = ColorUtil.Font.primary
        style.titleSelectedColor = ColorUtil.main
        style.bottomLineColor = ColorUtil.main
        style.bottomLineWidth = 17
        style.titleFont = FontUtil.bold(size: 15)
        for item in titles.enumerated() {
            if item.offset == 0 {
                let controller = ActivityPractiveController()
                titleMap[item.element] = controller
                addChild(controller)
            } else {
                let controller = ActivityHomeworkController()
                titleMap[item.element] = controller
                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
// MARK: - View
extension SLessonPreparationDetailsController {
    override func initView() {
        self.view.addSubview(mainView)
        mainView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        
        navigationBar = TKNormalNavigationBar.init(frame: CGRect.zero, title: "", target: self)
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initContentView()
    }
    
    func initContentView() {
        let titleView = pageViewManager.titleView
        mainView.addSubviews(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.width.equalTo(247)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        let contentView = pageViewManager.contentView
        mainView.addSubview(pageViewManager.contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleView.snp.bottom).offset(10)
            maker.left.right.bottom.equalToSuperview()
        }
    }
    
}
// MARK: - Data
extension SLessonPreparationDetailsController {
    override func initData() {
        
    }
}

// MARK: - TableView
extension SLessonPreparationDetailsController {
    
}

// MARK: - Action
extension SLessonPreparationDetailsController {
    
}

