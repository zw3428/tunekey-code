//
//  SAchievementController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//

import SnapKit
import UIKit

class SAchievementController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    private lazy var titles = ["Practice", "Milestones"]
    private var startRangeDate: Date! = Date().add(component: .day, value: -6).startOfDay
    private var endRangeDate: Date! = Date().endOfDay
    private lazy var titleMap = [String: TKBaseViewController]()
    private var practiceController: SAchievementPracticeController!
    private lazy var pageViewManager: PageViewManager = {
        // 创建DNSPageStyle，设置样式
        let style = PageStyle()
        style.isShowBottomLine = true
        style.isTitleViewScrollEnabled = false
        style.titleViewBackgroundColor = UIColor.clear
        style.isContentScrollEnabled = true
        style.titleColor = ColorUtil.Font.primary
        style.titleSelectedColor = ColorUtil.main
        style.bottomLineColor = ColorUtil.main
        style.bottomLineWidth = 17
        style.titleFont = FontUtil.bold(size: 15)
        for item in titles.enumerated() {
            if item.offset == 0 {
                let controller = SAchievementPracticeController()
                practiceController = controller
                controller.endRangeDate = endRangeDate
                controller.startRangeDate = startRangeDate
                titleMap[item.element] = controller
                addChild(controller)
            } else {
                let controller = SAchievementMilestonesController()
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

extension SAchievementController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Award", rightButton: UIImage(named: "icCalendarMain")!, target: self, onRightButtonTapped: {
            self.selectDateRange()
        })
        navigationBar.hiddenLeftButton()
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
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
        titleView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.width.equalTo(247)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        let contentView = pageViewManager.contentView
        mainView.addSubview(pageViewManager.contentView)
        contentView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom).offset(10)
            maker.left.right.bottom.equalToSuperview()
        }
        
        pageViewManager.contentView.scrollDelegate = self
        pageViewManager.titleView.clickHandler = { [weak self] _, index in
            guard let self = self else { return }
            if index == 1 {
                self.navigationBar.hiddenRightButton()
            } else {
                self.navigationBar.showRightButton()
            }
        }
    }
}

extension SAchievementController: PageContentViewScrollDelegate {
    func contentView(_ contentView: PageContentView, didSelectedAt index: Int) {
        if index == 1 {
            navigationBar.hiddenRightButton()
        } else {
            navigationBar.showRightButton()
        }
    }
    
}

// MARK: - Data

extension SAchievementController {
    override func initData() {
    }
}

// MARK: - TableView

extension SAchievementController {
}

extension SAchievementController {
    // MARK: - Action

    func selectDateRange() {
        let today = Date()
        let thisMonth = Date(year: today.year, month: today.month, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, region: .local)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        TKPopAction.show(items: [
            .item(title: "Next month", action: { [weak self] in
                let startDate = thisMonth.add(component: .month, value: 1)
                let endDate = startDate.add(component: .month, value: 1).add(component: .day, value: -1)
                logger.debug("当前选择的时间: \(dateFormatter.string(from: startDate)) | \(dateFormatter.string(from: endDate))")
                self?.refreshData(startTime: startDate.timestamp, endTime: endDate.timestamp)
            }),
            .item(title: "This month", action: { [weak self] in
                let startDate = thisMonth
                let endDate = startDate.add(component: .month, value: 1).add(component: .day, value: -1)
                logger.debug("当前选择的时间: \(dateFormatter.string(from: startDate)) | \(dateFormatter.string(from: endDate))")
                self?.refreshData(startTime: startDate.timestamp, endTime: endDate.timestamp)
            }),
            .item(title: "Last month", action: { [weak self] in
                let startDate = thisMonth.add(component: .month, value: -1)
                let endDate = thisMonth.add(component: .day, value: -1)
                logger.debug("当前选择的时间: \(dateFormatter.string(from: startDate)) | \(dateFormatter.string(from: endDate))")
                self?.refreshData(startTime: startDate.timestamp, endTime: endDate.timestamp)
            }),
            .item(title: "Last 3 months", action: { [weak self] in
                let startDate = thisMonth.add(component: .month, value: -2)
                let endDate = thisMonth.add(component: .month, value: 1).add(component: .day, value: -1)
                logger.debug("当前选择的时间: \(dateFormatter.string(from: startDate)) | \(dateFormatter.string(from: endDate))")
                self?.refreshData(startTime: startDate.timestamp, endTime: endDate.timestamp)
            }),
            .item(title: "Date range", action: { [weak self] in
                self?.customDateRange()
            }),
        ], isCancelShow: true, target: self)
    }

    private func customDateRange() {
        let controller = TKPopDateRangeSelectController()
        controller.startTime = startRangeDate.timestamp * 1000
        controller.endTime = endRangeDate.timestamp * 1000
        controller.modalPresentationStyle = .custom
        present(controller, animated: false) {
        }
        controller.confirmAction = { [weak self] startTime, endTime in
            guard let self = self else { return }
            self.refreshData(startTime: startTime, endTime: endTime)
        }
    }

    private func refreshData(startTime: Int, endTime: Int) {
        startRangeDate = TimeUtil.changeTime(time: Double(startTime))
        endRangeDate = TimeUtil.changeTime(time: Double(endTime)).endOfDay
        practiceController.refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
    }
}
