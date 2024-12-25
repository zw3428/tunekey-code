//
//  InsightsViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/8/5.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class InsightsViewController: TKBaseViewController {
    private var isPro: Bool = false

    private var upgradeProButton: TKButton!
    private var upgradeProLabel: TKLabel!
    private var upgradeProView: TKView!

    private var navigationBar: TKView!
    private var calendarButton: TKButton!
    private var contentView: TKView!
    // 1是免费 2是收费用户
    var teacherMemberLevel: Int = 1
    private lazy var titles = ["Teaching", "Earnings", "Learning"]
    private var teachingViewController: InsightsTeachingViewController!
    private var earningsViewController: InsightsEarningsViewController!
    private var learningViewController: InsightsLearningViewController!
    private var insightsCount = 0
    private var startRangeDate: Date = Date(year: Date().year, month: Date().month, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, region: .local).startOfDay
    private var endRangeDate: Date = Date(year: Date().year, month: Date().month, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, region: .local).startOfDay.add(component: .month, value: 1).add(component: .day, value: -1).endOfDay

    private let calendarButtonIconSize: CGSize = CGSize(width: 22, height: 22)
    private var isCalendarFilterShow: Bool = false {
        didSet {
            if isCalendarFilterShow {
                calendarButton.setImage(name: "lessons_selected", size: calendarButtonIconSize)
                teachingViewController.showCalendarFilterView()
                earningsViewController.showCalendarFilterView()
                learningViewController.showCalendarFilterView()
            } else {
                calendarButton.setImage(name: "lessons", size: calendarButtonIconSize)
                teachingViewController.hideCalendarFilterView()
                earningsViewController.hideCalendarFilterView()
                learningViewController.hideCalendarFilterView()
            }
        }
    }

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
        style.isContentScrollEnabled = true
        style.titleFont = FontUtil.bold(size: 15)

        for item in titles.enumerated() {
            switch item.offset {
            case 0:
                let controller = InsightsTeachingViewController()
                teachingViewController = controller
                teachingViewController.startRangeDate = startRangeDate
                teachingViewController.endRangeDate = endRangeDate

                teachingViewController.delegate = self
                addChild(controller)
            case 1:
                let controller = InsightsEarningsViewController()
                earningsViewController = controller
                earningsViewController.startRangeDate = startRangeDate
                earningsViewController.endRangeDate = endRangeDate
                earningsViewController.delegate = self
                addChild(controller)
            default:
                let controller = InsightsLearningViewController()
                learningViewController = controller
                learningViewController.startRangeDate = startRangeDate
                learningViewController.endRangeDate = endRangeDate
                learningViewController.delegate = self
                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()

    private let insightsLimitCount: Int = 10

    override func onViewAppear() {
        super.onViewAppear()
//        getTeacherFirstLessonTime()
        Tools.addInsightsViewCount()
    }
}

// MARK: - view

extension InsightsViewController {
    override func initView() {
        view.backgroundColor = ColorUtil.backgroundColor
        initNavigationBar()
        initContentView()
        initUpgradeProView()
    }

    private func initNavigationBar() {
        navigationBar = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        addSubview(view: navigationBar) { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.height.equalTo(44)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 18))
            .textColor(color: ColorUtil.Font.fourth)
            .alignment(alignment: .center)
            .text(text: "Insights")
        titleLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 1)
        navigationBar.addSubview(view: titleLabel) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }
        calendarButton = TKButton()
            .setImage(name: "lessons_selected", size: CGSize(width: 22, height: 22))
        navigationBar.addSubview(view: calendarButton) { make in
            make.centerY.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-20)
            make.size.equalTo(22)
        }
    }

    private func initContentView() {
        contentView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        addSubview(view: contentView) { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        let titleView = pageViewManager.titleView
        contentView.addSubview(view: titleView) { make in
            make.top.equalToSuperview()
            make.width.equalTo(247)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        upgradeProView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
        contentView.addSubview(view: upgradeProView) { make in
            make.top.equalTo(pageViewManager.titleView.snp.bottom).offset(20)
            make.width.equalToSuperview()
            make.height.equalTo(24)
        }
        contentView.addSubview(view: pageViewManager.contentView) { make in
            make.top.equalTo(upgradeProView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func initUpgradeProView() {
        upgradeProView.layer.masksToBounds = true
        upgradeProButton = TKButton.create()
            .title(title: "PRO")
            .titleFont(font: FontUtil.medium(size: 8.2))
            .titleColor(color: UIColor.white)
        upgradeProButton.layer.cornerRadius = 3
        upgradeProButton.backgroundColor = UIColor(named: "red")!
        upgradeProButton.setShadows(color: UIColor(named: "red")!, withBorder: false)
        upgradeProView.addSubview(view: upgradeProButton) { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(24)
            make.right.equalToSuperview().offset(-20)
        }
        upgradeProLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 10))
            .textColor(color: ColorUtil.Font.primary)
            .alignment(alignment: .left)
//            .text(text: "You've reached your limit of 100 views.\nTry PRO to unlock the full power of TuneKey.")
            .text(text: "You should upgrade Insights to pro.\nTry PRO to unlock the full power of TuneKey.")
        upgradeProLabel.numberOfLines = 2
        upgradeProLabel.changeLabelRowSpace(lineSpace: 0, wordSpace: 0.3)
        upgradeProView.addSubview(view: upgradeProLabel) { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(upgradeProButton.snp.left).offset(-20)
        }
    }
}

// MARK: - events

extension InsightsViewController {
    override func bindEvent() {
        upgradeProButton.onTapped { _ in
            logger.debug("upgrade pro tapped")
            ProfileUpgradeDetailViewController.show(level: .normal, target: self)
        }
        calendarButton.onTapped { [weak self] _ in
            logger.debug("calendar button tapped")
//            self?.isCalendarFilterShow.toggle()
            self?.selectDateRange()
        }
    }
}

extension InsightsViewController {
    // MARK: - data

    override func initData() {
        EventBus.listen(EventBus.CHANGE_MEMBER_LEVEL_ID, target: self) { [weak self] data in
            guard let self = self else { return }
            if let data: Bool = data!.object as? Bool {
                if data {
                    self.teacherMemberLevel = 2
                } else {
                    self.teacherMemberLevel = 1
                }
                self.initUserInfo()
            }
        }
        getInsightsCount()
    }

    /// 获取老师第一次上课的时间
//    func getTeacherFirstLessonTime() {
//        var isLoad = false
//        addSubscribe(
//            LessonService.lessonSchedule.getTeacherFirstLesson(teacherId: UserService.user.id()!)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self, !isLoad else { return }
//                    for doc in docs.documents {
//                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
//                            isLoad = true
//                            self.teachingViewController.refreshData(startTimestamp: TimeUtil.changeTime(time: doc.shouldDateTime).startOfDay.timestamp)
//                        }
//                    }
//
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }

    func getInsightsCount() {
        showFullScreenLoading()
        var isLoad = false
        guard let id = UserService.user.id() else { return }
        addSubscribe(
            UserService.teacher.getInsightsCount(id: id)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    if isLoad {
                        return
                    }
                    isLoad = true
                    if doc.exists {
                        if let count: Int = (doc.data()!["count"]) as? Int {
                            logger.debug("insights count: \(count)")
                            self.insightsCount = count
                            upDateInsightsCount()
                        }
                        self.getUserInfo()
                    } else {
                        logger.debug("====== 空")
                        self.insightsCount = 0
                        upDateInsightsCount()

                        self.getUserInfo()
                    }

                }, onError: { [weak self] err in
                    upDateInsightsCount()
                    self?.getUserInfo()
                    logger.debug("获取失败:\(err)")
                })
        )
        func upDateInsightsCount() {
            insightsCount += 1

            UserService.teacher.updateInsightsCount(count: insightsCount)
        }
    }

    func getUserInfo() {
        addSubscribe(
            UserService.teacher.studentGetTeacherInfo(teacherId: UserService.user.id()!)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.hideFullScreenLoading()
                        self.teacherMemberLevel = data.memberLevelId
                        self.initUserInfo()
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.initUserInfo()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func initUserInfo() {
        print("==sdsdsdsdsdsd==\(insightsCount)")
        if teacherMemberLevel == 1 && insightsCount >= insightsLimitCount {
            upgradeProView.snp.updateConstraints { make in
                make.height.equalTo(24)
            }

            pageViewManager.contentView.snp.updateConstraints { make in
                make.top.equalTo(upgradeProView.snp.bottom).offset(20)
            }
        } else {
            upgradeProView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            pageViewManager.contentView.snp.updateConstraints { make in
                make.top.equalTo(upgradeProView.snp.bottom).offset(0)
            }
        }
        teachingViewController.insightsCount = insightsCount
        teachingViewController.teacherMemberLevel = teacherMemberLevel
        earningsViewController.insightsCount = insightsCount
        earningsViewController.teacherMemberLevel = teacherMemberLevel
        learningViewController.insightsCount = insightsCount
        learningViewController.teacherMemberLevel = teacherMemberLevel
    }
}

extension InsightsViewController: InsightsCalendarFilterViewDelegate {
    func insightsCalendarFilterViewIsShow() -> Bool {
        isCalendarFilterShow
    }
}

extension InsightsViewController {
    // MARK: - Action

    func selectDateRange() {
        let today = Date()
        let thisMonth = Date(year: today.year, month: today.month, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, region: .local).startOfDay
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        TKPopAction.show(items: [
            .item(title: "Next month", action: { [weak self] in
                let startDate = thisMonth.add(component: .month, value: 1)
                let endDate = startDate.add(component: .month, value: 1).add(component: .day, value: -1)
                logger.debug("当前选择的时间: \(dateFormatter.string(from: startDate)) | \(dateFormatter.string(from: endDate))===\(startDate.timestamp)===\(thisMonth.timestamp)")
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
            .item(title: "Last 2 months", action: { [weak self] in
                let startDate = thisMonth.add(component: .month, value: -1)
                let endDate = thisMonth.add(component: .month, value: 1).add(component: .day, value: -1)
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
        let _today = Date()
        let today = Date(year: _today.year, month: _today.month, day: _today.day, hour: 23, minute: 59, second: 59)
        if endRangeDate.timestamp >= today.timestamp {
            controller.endTime = today.timestamp * 1000
        } else {
            controller.endTime = endRangeDate.timestamp * 1000
        }
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
        learningViewController.refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
        earningsViewController.refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
        teachingViewController.refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
    }
}

protocol InsightsCalendarFilterViewDelegate: NSObjectProtocol {
    func insightsCalendarFilterViewIsShow() -> Bool
}
