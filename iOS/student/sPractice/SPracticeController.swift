//
//  SPracticeController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/18.
//  Copyright © 2019年 spelist. All rights reserved.
//
import SwiftDate
import AVFoundation
import SnapKit
import UIKit

public var currentSelectedPracticeDate: Date?

class SPracticeController: TKBaseViewController {
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var mainController: MainViewController?
    private lazy var titles = ["Log Sheet", "Metronome"]
    private lazy var titleMap = [String: TKBaseViewController]()
    var logController: PracticeLogController!
    private var recordController: RecordingController?
    private var schedule: TKLessonSchedule?

    // 上一次加载的起始时间 previous
    private var previousCount: Int = 0
    // 上上次
    private var previousPreviousCount: Int = 0
    private var isLRefresh = false
    var practiceData: [TKPracticeAssignment] = []
    private var preLessonData: TKLessonSchedule?
    private var isLoadPreAssignmenData = false
    private var allData: [TKPracticeAssignment] = []
    var practiceHistoryData: [TKPractice] = []
    var startTimestamp = 0
    var endTimestamp = 0

    var bottomLayout: TKView!
    var logButton: TKBlockButton!
    var startPracticeButton: TKBlockButton!
    private var logForPreviewsDaysButton: TKButton = TKButton.create()
        .title(title: "Log for previous days")
        .titleColor(color: ColorUtil.main)
        .titleFont(font: FontUtil.medium(size: 13))

    private lazy var pageViewManager: PageViewManager = {
        // 创建DNSPageStyle，设置样式
        let style = PageStyle()
        style.isShowBottomLine = true
        style.isTitleViewScrollEnabled = false
        style.isContentScrollEnabled = true
        style.titleViewBackgroundColor = UIColor.clear
        style.titleColor = ColorUtil.Font.primary
        style.titleSelectedColor = ColorUtil.main
        style.bottomLineColor = ColorUtil.main
        style.bottomLineWidth = 17
        style.titleFont = FontUtil.bold(size: 15)
        for item in titles.enumerated() {
            if item.offset == 0 {
                let controller = PracticeLogController()
                controller.targetController = self
                titleMap[item.element] = controller
                logController = controller
                addChild(controller)
            } else {
                let controller = PracticeMilestonesController()
                controller.targetController = self
                titleMap[item.element] = controller
                addChild(controller)
            }
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("=====我要关闭了 ")
        EventBus.send(EventBus.STOP_METRONOME)
    }
}

// MARK: - View

extension SPracticeController: PageContentViewScrollDelegate {
    func contentView(_ contentView: PageContentView, didSelectedAt index: Int) {
//        checkBottomButtons(at: index)
//        refreshBottomButton(at: index)
    }

    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        mainView.backgroundColor = ColorUtil.backgroundColor
        navigationBar = TKNormalNavigationBar(frame: .zero, title: "Practice", target: self)
        navigationBar.hiddenLeftButton()

        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initButtonLayout()
        initContentView()
    }

    func initButtonLayout() {
        bottomLayout = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(126)
            })
        bottomLayout.setTopRadius()
        logButton = TKBlockButton(frame: CGRect.zero, title: "LOG", style: .cancel)
        bottomLayout.addSubview(view: logButton) { make in
            make.width.equalToSuperview().multipliedBy(0.336)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.left.equalTo(20)
        }

        startPracticeButton = TKBlockButton(frame: CGRect.zero, title: "RECORD PRACTICE", style: .normal)
        bottomLayout.addSubview(view: startPracticeButton) { make in
            make.width.equalToSuperview().multipliedBy(0.504)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(50)
            make.right.equalToSuperview().offset(-20)
        }

        logForPreviewsDaysButton.addTo(superView: bottomLayout) { make in
            make.top.equalTo(logButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(16)
        }

        startPracticeButton.onTapped { [weak self] _ in
            self?.onRecordPracticeButtonTapped()
        }
        logButton.onTapped { [weak self] _ in
            self?.clickLogButton()
        }
        logForPreviewsDaysButton.onTapped { [weak self] _ in
            self?.onLogForPreviewsDaysButtonTapped()
        }
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
        contentView.setScrollEnabled(isEnabled: false)
        contentView.scrollDelegate = self
        mainView.addSubview(pageViewManager.contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.bottom.equalTo(bottomLayout.snp.top)
            make.left.right.equalToSuperview()
        }
    }

    func refreshBottomButton(at: Int) {
        if at == 0 {
            logButton.enable()
        } else {
            logButton.disable()
        }
    }
}

// MARK: - Data

extension SPracticeController {
    override func bindEvent() {
        super.bindEvent()
        EventBus.listen(key: .parentKidSelected, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }
        
        EventBus.listen(key: .parentDataLoaded, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.loadData()
        }
    }
    override func initData() {
        practiceData = []
        allData = []
        let d = Date()
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -3)).timestamp
        endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
//        showFullScreenLoading()
        let today = Date().startOfDay
        var pData = TKPracticeAssignment()
        pData.startTime = today.timeIntervalSince1970
        pData.endTime = today.timeIntervalSince1970 + 86399
        practiceData.append(pData)
        allData.append(pData)

//        getPreLesson()
//        getPracticeData()

        loadData()

        EventBus.listen(EventBus.CHANGE_PRACTICE, target: self) { [weak self] _ in
            guard let self = self else { return }
            EventBus.send(EventBus.CHANGE_SCHEDULE)
            self.loadData()
//            self.endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
//            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -3)).timestamp
//            self.logController?.isLRefresh = false
//            self.isLoadPreAssignmenData = false
//            self.previousCount = 0
//            self.previousPreviousCount = 0
//            self.logController?.addedPracticeIds = []
//            self.practiceData = []
//            self.practiceData.append(pData)
//            self.allData.append(pData)
////            self.getPracticeData()
//            guard let student = StudentService.student else { return }
//            StudentService.practice.getPractice(withStudioId: student.studioId, studentId: student.studentId, dateTimeRange: DateTimeRange(startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp)))
//                .done { data in
//                    logger.debug("获取到练习数据, 参数: \(student.studioId) | \(student.studentId) |")
//                    self.initShowData(data: data)
//                }
//                .catch { error in
//                    logger.error("获取练习数据失败: \(error)")
//                }
        }
    }
    
    private func loadData() {
        akasync { [weak self] in
            guard let self = self else { return }
            guard let student = StudentService.student else {
                updateUI {
                    self.sortData()
                    self.logController?.refData(data: self.practiceData, newCount: 1)
                    self.initShowData(data: [])
                    self.navigationBar.stopLoading()
                }
                return
            }
            do {
                logger.debug("开始加载练习数据记录")
                updateUI {
                    self.navigationBar.startLoading()
                }
//                let previousLesson = try akawait(StudentService.practice.getPreviousLesson(withStudioId: student.studioId, studentId: student.studentId))
                let previousLesson = try akawait(LessonService.lessonSchedule.getPreviousLesson(withStudentId: student.studentId))
                logger.debug("获取到的上一节课的数据: \(previousLesson?.toJSONString() ?? "")")
                let practiceData = try akawait(StudentService.practice.getPractice(withStudioId: student.studioId, studentId: student.studentId, dateTimeRange: DateTimeRange(startTime: TimeInterval(self.startTimestamp), endTime: TimeInterval(self.endTimestamp))))
                logger.debug("获取到的练习数据: \(practiceData.toJSONString() ?? "")")
                updateUI {
                    self.preLessonData = previousLesson
//                    var addData: [TKPractice] = []
//                    var needAddData: [TKPractice] = []
//
//                    if let previousLesson = previousLesson {
//                        for item in self.allData {
//                            for practiceItem in item.practice where practiceItem.lessonScheduleId == previousLesson.id {
//                                addData.append(practiceItem)
//                            }
//                        }
//                    }
//                    logger.debug("要添加的练习数据11: \(addData.compactMap({ "\($0.id) | \($0.assignmentId)" }))")
//                    for addItem in addData {
//                        var isHave = false
//                        for item in self.practiceData[0].practice where addItem.id == item.id || addItem.assignmentId == item.assignmentId {
//                            isHave = true
//                        }
//                        logger.debug("是否已经存在 111: \(addItem.assignmentId) | \(self.practiceData[0].practice.compactMap({ $0.assignmentId }))")
//                        if !isHave, !self.isLoadPreAssignmenData {
//                            let add = TKPractice()
//                            let id = "\(IDUtil.nextId(group: .audio) ?? 0)"
//                            add.id = id
//                            add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
//                            add.totalTimeLength = 0
//                            add.done = false
//                            add.recordData = []
//                            add.name = addItem.name
//                            add.studentId = addItem.studentId
//                            add.teacherId = addItem.teacherId
//                            add.assignment = true
//                            add.assignmentId = addItem.assignmentId
//                            add.scheduleConfigId = addItem.scheduleConfigId
//                            add.lessonScheduleId = addItem.lessonScheduleId
//                            add.shouldDateTime = addItem.shouldDateTime
//                            add.createTime = addItem.createTime
//                            add.updateTime = addItem.updateTime
//                            self.practiceData[0].practice.append(add)
//                            needAddData.append(add)
//                        }
//                    }
//                    if needAddData.count > 0 {
//                        logger.debug("添加课程 1111: \(needAddData.toJSONString() ?? "")")
//                        self.isLoadPreAssignmenData = true
//                        self.addPractices(data: needAddData)
//                    }

                    self.sortData()
                    self.logController?.refData(data: self.practiceData, newCount: 1)
                    self.initShowData(data: practiceData)
                    self.navigationBar.stopLoading()
                }
            } catch {
                updateUI {
                    self.navigationBar.stopLoading()
                }
                logger.error("加载练习数据出错: \(error)")
            }
        }
    }

    // 顺序:未完成->作业->时间顺序排序练习
    /// 获取上一节课
//    private func getPreLesson() {
//        guard let userId = UserService.user.id() else { return }
//        LessonService.lessonSchedule.getPreviousLesson(withStudentId: userId)
//            .done { [weak self] data in
//                guard let self = self else { return }
//                if let data = data {
//                    logger.debug("获取到的上一节课: \(data.toJSONString() ?? "")")
//                    logger.debug("当前的所有作业数据: \(self.allData.count)")
//                    self.preLessonData = data
//                    var addData: [TKPractice] = []
//                    var needAddData: [TKPractice] = []
//
//                    for item in self.allData {
//                        for practiceItem in item.practice where practiceItem.lessonScheduleId == data.id {
//                            addData.append(practiceItem)
//                        }
//                    }
//                    for addItem in addData {
//                        var isHave = false
//                        for item in self.practiceData[0].practice where addItem.id == item.id || addItem.assignmentId == item.assignmentId {
//                            isHave = true
//                        }
//                        if !isHave, !self.isLoadPreAssignmenData {
//                            let add = TKPractice()
//                            let id = "\(IDUtil.nextId(group: .audio) ?? 0)"
//                            add.id = id
//                            add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
//                            add.totalTimeLength = 0
//                            add.done = false
//                            add.recordData = []
//                            add.name = addItem.name
//                            add.studentId = addItem.studentId
//                            add.teacherId = addItem.teacherId
//                            add.assignment = true
//                            add.assignmentId = addItem.assignmentId
//                            add.scheduleConfigId = addItem.scheduleConfigId
//                            add.lessonScheduleId = addItem.lessonScheduleId
//                            add.shouldDateTime = addItem.shouldDateTime
//                            add.createTime = addItem.createTime
//                            add.updateTime = addItem.updateTime
//                            self.practiceData[0].practice.append(add)
//                            needAddData.append(add)
//                        }
//                    }
//                    if needAddData.count > 0 {
//                        self.isLoadPreAssignmenData = true
//                        self.addPractices(data: needAddData)
//                    }
//
//                    self.sortData()
//                    self.logController?.refData(data: self.practiceData, newCount: 1)
//                }
//            }
//            .catch { error in
//                logger.error("获取上一节课失败: \(error)")
//            }
////        addSubscribe(
////            LessonService.lessonSchedule.getPreviousLessonByStudentId(studentId: userId)
////                .subscribe(onNext: { [weak self] docs in
////                    guard let self = self else { return }
////                    var data: TKLessonSchedule?
////                    for doc in docs.documents {
////                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
////                            data = doc
////                        }
////                    }
////                    if let data = data {
////                        logger.debug("获取到的上一节课: \(data.toJSONString() ?? "")")
////                        logger.debug("当前的所有作业数据: \(self.allData.count)")
////                        self.preLessonData = data
////                        var addData: [TKPractice] = []
////                        var needAddData: [TKPractice] = []
////
////                        for item in self.allData {
////                            for practiceItem in item.practice where practiceItem.lessonScheduleId == data.id {
////                                addData.append(practiceItem)
////                            }
////                        }
////                        for addItem in addData {
////                            var isHave = false
////                            for item in self.practiceData[0].practice where addItem.id == item.id || addItem.assignmentId == item.assignmentId {
////                                isHave = true
////                            }
////                            if !isHave, !self.isLoadPreAssignmenData {
////                                let add = TKPractice()
////                                let id = "\(IDUtil.nextId(group: .audio) ?? 0)"
////                                add.id = id
////                                add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
////                                add.totalTimeLength = 0
////                                add.done = false
////                                add.recordData = []
////                                add.name = addItem.name
////                                add.studentId = addItem.studentId
////                                add.teacherId = addItem.teacherId
////                                add.assignment = true
////                                add.assignmentId = addItem.assignmentId
////                                add.scheduleConfigId = addItem.scheduleConfigId
////                                add.lessonScheduleId = addItem.lessonScheduleId
////                                add.shouldDateTime = addItem.shouldDateTime
////                                add.createTime = addItem.createTime
////                                add.updateTime = addItem.updateTime
////                                self.practiceData[0].practice.append(add)
////                                needAddData.append(add)
////                            }
////                        }
////                        if needAddData.count > 0 {
////                            self.isLoadPreAssignmenData = true
////                            self.addPractices(data: needAddData)
////                        }
////
////                        self.sortData()
////                        self.logController?.refData(data: self.practiceData, newCount: 1)
////                    }
////
////                }, onError: { err in
////                    logger.debug("获取失败:\(err)")
////                })
////        )
//    }

    private func sortData() {
        practiceData.forEachItems { _, offset in
            self.practiceData[offset].practice.sort { data0, data1 -> Bool in
                data0.startTime > data1.startTime
            }
            self.practiceData[offset].practice.sort { data0, _ -> Bool in
                data0.assignment
            }
            self.practiceData[offset].practice.sort { data0, _ -> Bool in
                !data0.done
            }
        }
    }

    private func addPractices(data: [TKPractice]) {
        logger.debug("最后判断是否已经存在: \(practiceData[0].practice.compactMap({ $0.assignmentId })) | 要添加的: \(data.compactMap({ $0.assignmentId }))")
        var willAdd: [TKPractice] = []
        for item in data {
            if !practiceData[0].practice.contains(where: { $0.assignmentId == item.assignmentId }) {
                willAdd.append(item)
            }
        }
        logger.debug("最后判断是否已经存在: 实际要添加的: \(willAdd.toJSONString() ?? "")")
        if willAdd.isNotEmpty {
            addSubscribe(
                LessonService.lessonSchedule.addPractices(data: willAdd)
                    .subscribe(onNext: { _ in
                        logger.debug("====add成功==")
                    }, onError: { err in
                        logger.debug("====add失败==\(err)")
                    })
            )
        }
    }

    func getPracticeData() {
        guard let userId = UserService.user.id() else { return }
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp), studentId: userId)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if var data = data[.cache] {
                        data.sort { a, b -> Bool in
                            a.startTime > b.startTime
                        }
                        logger.debug("根据参数获取练习数据: \(startTimestamp) - \(endTimestamp) | \(TimeInterval(startTimestamp).toFormat("yyyy-MM-dd HH:mm:ss")) - \(TimeInterval(endTimestamp).toFormat("yyyy-MM-dd HH:mm:ss")) | \(userId)")
                        self.initShowData(data: data)
                    }
                    if var data = data[.server] {
                        data.sort { a, b -> Bool in
                            a.startTime > b.startTime
                        }
                        logger.debug("根据参数获取练习数据: \(startTimestamp) - \(endTimestamp) | \(TimeInterval(startTimestamp).toFormat("yyyy-MM-dd HH:mm:ss")) - \(TimeInterval(endTimestamp).toFormat("yyyy-MM-dd HH:mm:ss")) | \(userId)")
                        self.initShowData(data: data)
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func initShowData(data: [TKPractice]) {
        for item in data {
            let startOfDayTime = DateInRegion(seconds: item.startTime, region: .localRegion).dateAtStartOf(.day).timeIntervalSince1970
            logger.debug("[计算练习数据] => 当前item: \(item.id) 的开始时间: \(item.startTime.toFormat("yyyy-MM-dd HH:mm:ss")) 对应的日期：\(startOfDayTime.toFormat("yyyy-MM-dd HH:mm:ss")) | 今天开始的时间: \(DateInRegion(region: .localRegion).timeIntervalSince1970.toFormat("yyyy-MM-dd HH:mm:ss"))")
            guard item.done || (startOfDayTime == Date().startOfDay.timeIntervalSince1970 && item.assignment) else { continue }
            // 是不是已经有了这一天你的记录了
            var isHave = false
            for practiceItme in practiceData.enumerated() where practiceItme.element.startTime == startOfDayTime {
                isHave = true
                // 是不是已经有了practice
                var isHavePractice = false
                for pItem in practiceData[practiceItme.offset].practice where item.id == pItem.id {
                    isHavePractice = true
                }
                if !isHavePractice {
                    practiceData[practiceItme.offset].practice.append(item)
                }
            }
            if !isHave {
                var pData = TKPracticeAssignment()
                pData.startTime = startOfDayTime
                pData.endTime = startOfDayTime + 86399
                pData.practice.append(item)
                practiceData.append(pData)
            }
        }
        logger.debug("第一遍处理之后的数据： \(practiceData.toJSONString() ?? "")")

        for item in data {
            let startOfDayTime = TimeUtil.changeTime(time: item.startTime).startOfDay.timeIntervalSince1970
            // 是不是已经有了这一天你的记录了
//            if !item.assignment {
            var historyIsHave = false
            for historyItem in practiceHistoryData where historyItem.id == item.id {
                historyIsHave = true
            }
            if !historyIsHave {
                practiceHistoryData.append(item)
            }
//            }
            var isHave = false
            for practiceItme in allData.enumerated() where practiceItme.element.startTime == startOfDayTime {
                isHave = true
                // 是不是已经有了practice
                var isHavePractice = false
                for pItem in allData[practiceItme.offset].practice where item.id == pItem.id {
                    isHavePractice = true
                }
                if !isHavePractice {
                    allData[practiceItme.offset].practice.append(item)
                }
            }
            if !isHave {
                var pData = TKPracticeAssignment()
                pData.startTime = startOfDayTime
                pData.endTime = startOfDayTime + 86399
                pData.practice.append(item)
                allData.append(pData)
            }
        }

        if data.count > 0 {
            previousCount += 1
        }
        var needAddData: [TKPractice] = []
        if let previousLesson = preLessonData, !isLoadPreAssignmenData {
            var addData: [TKPractice] = []
            for item in allData {
                for practiceItem in item.practice where practiceItem.lessonScheduleId == previousLesson.id {
                    addData.append(practiceItem)
                }
            }
            logger.debug("要添加的练习数据22: \(addData.compactMap({ "\($0.id) | \($0.assignmentId)" }))")
            for addItem in addData {
                var isHave = false
                for item in practiceData[0].practice where addItem.id == item.id || addItem.assignmentId == item.assignmentId {
                    isHave = true
                }
                logger.debug("是否已经存在 222: \(addItem.assignmentId) | \(practiceData[0].practice.compactMap({ $0.assignmentId }))")
                if !isHave, !isLoadPreAssignmenData {
                    let add = TKPractice()
                    let id = "\(IDUtil.nextId(group: .audio) ?? 0)"
                    add.id = id
                    add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
                    add.totalTimeLength = 0
                    add.done = false
                    add.recordData = []
                    add.assignment = true
                    add.name = addItem.name
                    add.studentId = addItem.studentId
                    add.teacherId = addItem.teacherId
                    add.assignmentId = addItem.assignmentId
                    add.scheduleConfigId = addItem.scheduleConfigId
                    add.lessonScheduleId = addItem.lessonScheduleId
                    add.shouldDateTime = addItem.shouldDateTime
                    add.createTime = addItem.createTime
                    add.updateTime = addItem.updateTime
                    practiceData[0].practice.append(add)
                    needAddData.append(add)
                }
            }
        }
        logger.debug("最后计算出来要添加的数据数量：\(needAddData.count) | \(needAddData.toJSONString() ?? "")")
        if needAddData.count > 0 {
            logger.debug("最后要添加的练习数据 222: \(needAddData.toJSONString() ?? "")")
            isLoadPreAssignmenData = true
//            addPractices(data: needAddData)
        }
        practiceData.forEachItems { _, offset in
            practiceData[offset].practice.sort { _, b -> Bool in
                b.done
            }
        }

        previousPreviousCount = previousCount
        previousCount = 0
        hideFullScreenLoading()
        sortData()
        logController?.refData(data: practiceData, newCount: data.count)
    }

    func upload(data: TKPractice, uploadData: [H5PracticeRecord], practices: [TKPractice]) {
        OperationQueue.main.addOperation {
            self.showFullScreenLoadingNoAutoHide()
        }

        complete(data: data, isShowLoading: false, practices: practices, uploadData: uploadData)
    }

    func complete(data: TKPractice, isShowLoading: Bool, practices: [TKPractice], uploadData: [H5PracticeRecord]? = nil) {
        if isShowLoading {
            OperationQueue.main.addOperation {
                self.showFullScreenLoadingNoAutoHide()
            }
        }
        for (i, item) in data.recordData.enumerated() {
            if item.format != ".mp4" {
                data.recordData[i].upload = false
                var fileSize: Int = 0
                var startTime: TimeInterval = 0
                do {
                    let attritubes = try FileManager.default.attributesOfItem(atPath: "\(RecorderTool.sharedManager.composeDir())log-\(item.id)\(item.format)")
                    if let fs = attritubes[FileAttributeKey.size] as? UInt64 {
                        fileSize = Int(fs)
                    }
                    if let createDate = attritubes[FileAttributeKey.creationDate] as? Date {
                        logger.debug("获取到文件创建的时间: \(createDate)")
                        startTime = createDate.timeIntervalSince1970
                    }
                } catch {
                    logger.error("获取文件大小失败: \(error)")
                }
                data.recordData[i].fileSize = fileSize
                if startTime != 0 {
                    data.recordData[i].startTime = startTime
                }
            }
        }
        logger.debug("要上传的练习数据: \(data.toJSONString() ?? "")")
        addSubscribe(
            LessonService.lessonSchedule.updatePractice(id: data.id, data: ["done": true, "totalTimeLength": data.totalTimeLength, "recordData": data.recordData.toJSON()])
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.hideFullScreenLoading()
                        self.recordController?.hide()
                        let controller = TKPracticeRecordingListViewController(data, style: .studentCompletePracticeWithAudio)
                        controller.modalPresentationStyle = .custom
                        Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
                    }
                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }
}

// MARK: - Action

extension SPracticeController {
    private func onRecordPracticeButtonTapped() {
        let data = organizePracticeHistoryData()
        TKPopAction.show(items: [
            .init(title: "Audio Recording", action: { [weak self] in
                guard let self = self else { return }
                let controller = TKPopRecordPracticeController()
                controller.practiceType = .practice
                controller.practiceHistoryData = self.practiceHistoryData.filterDuplicates({ $0.assignmentId }).filterDuplicates({ $0.id })
                controller.titleString = "Record Practice"
                controller.practiceData = data
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
                controller.confirmAction = { [weak self] practices in
                    guard let self = self else { return }
                    logger.debug("选择的练习数据: \(practices.toJSONString() ?? "")")
                    self.showRecordingController(practices: practices)
                }
            }),
            .init(title: "Video Recording", action: { [weak self] in
                guard let self = self else { return }
                let controller = TKPopRecordPracticeController()
                controller.practiceType = .practice
                controller.practiceHistoryData = self.practiceHistoryData
                controller.titleString = "Record Practice"
                controller.practiceData = data
                controller.modalPresentationStyle = .custom
                Tools.getTopViewController()?.present(controller, animated: false, completion: nil)
                controller.confirmForVideo = { practice in
                    // 判断是否授权
                    guard let topController = Tools.getTopViewController() else { return }
                    let toVideoRecorder = {
                        DispatchQueue.main.async {
                            logger.debug("选择的练习数据: \(practice.toJSONString() ?? "")")
                            let controller = TKVideoRecorderViewController(practice)
                            controller.originalData = data
                            controller.originalPracticeHistory = self.practiceHistoryData
                            controller.modalPresentationStyle = .fullScreen
                            Tools.getTopViewController()?.present(controller, animated: true, completion: nil)
                        }
                    }
                    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    switch authStatus {
                    case .notDetermined:
                        AVCaptureDevice.requestAccess(for: .video) { enabled in
                            if enabled {
                                toVideoRecorder()
                            } else {
                                SL.Alert.show(target: topController, title: "Permission denied", message: "Camera permission has been denied, go to setting to enable it.", leftButttonString: "GO BACK", rightButtonString: "To Settings") {
                                } rightButtonAction: {
                                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }
                        }
                    case .restricted:
                        SL.Alert.show(target: topController, title: "Warning", message: "Can't connect to your camera for some reason, please try again later.", centerButttonString: "GOT IT") {
                        }
                    case .denied:
                        SL.Alert.show(target: topController, title: "Permission denied", message: "Camera permission has been denied, go to setting to enable it.", leftButttonString: "GO BACK", rightButtonString: "To Settings") {
                        } rightButtonAction: {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }

                        return
                    case .authorized:
                        toVideoRecorder()
                    @unknown default:
                        SL.Alert.show(target: topController, title: "Warning", message: "Can't connect to your camera for some reason, please try again later.", centerButttonString: "GOT IT") {
                        }
                    }
                }
            }),
        ], target: self)
    }

    private func organizePracticeHistoryData() -> [TKPractice] {
        guard practiceData.count > 0 else {
            return []
        }
        let data = practiceData[0].practice.filter { data -> Bool in
            data.assignment
        }
        data.forEachItems { item, _ in
            for hItem in practiceHistoryData.enumerated().reversed() where hItem.element.name.trimmingCharacters(in: .whitespaces) == item.name.trimmingCharacters(in: .whitespaces) {
                practiceHistoryData.remove(at: hItem.offset)
            }
        }
        practiceHistoryData = practiceHistoryData.filterDuplicates({ $0.name.trimmingCharacters(in: .whitespaces) }).filterDuplicates({ $0.assignmentId }).filterDuplicates({ $0.id })
        return data.filterDuplicates({ $0.assignmentId })
    }

    func clickLogButton() {
        // 此写法为只显示作业
        let data: [TKPractice] = practiceData[0].practice.filter({ $0.assignment }).filterDuplicates({ $0.name.trimmingCharacters(in: .whitespacesAndNewlines) })
        data.forEachItems { item, _ in
            for hItem in practiceHistoryData.enumerated().reversed() where hItem.element.name.trimmingCharacters(in: .whitespaces) == item.name.trimmingCharacters(in: .whitespaces) {
                practiceHistoryData.remove(at: hItem.offset)
            }
        }
        practiceHistoryData = practiceHistoryData.filterDuplicates({ $0.name.trimmingCharacters(in: .whitespaces) })
        logger.debug("选择要log的数据: \(data.toJSONString() ?? "")")
        let controller = TKPopRecordPracticeController()
        controller.practiceType = .log
        controller.practiceHistoryData = practiceHistoryData
        controller.titleString = "Log Manually"
        controller.practiceData = data
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.confirmLog = { [weak self] in
            guard let self = self else { return }
            if self.pageViewManager.titleView.currentIndex == 1 {
                self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 0, progress: 1)
                self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 0)
                self.pageViewManager.titleView.currentIndex = 0
                self.pageViewManager.contentView.currentIndex = 0
            }
        }
//        //此写法为显示自己添加的log
//        practiceData[0].practice.forEachItems { item, _ in
//            for hItem in practiceHistoryData.enumerated().reversed() where hItem.element.name == item.name {
//                practiceHistoryData.remove(at: hItem.offset)
//            }
//        }
//        practiceHistoryData = practiceHistoryData.filterDuplicates({ $0.name })
//        let controller = TKPopRecordPracticeController()
//        controller.practiceType = .log
//        controller.practiceHistoryData = practiceHistoryData
//        controller.titleString = "Log Manually"
//        controller.practiceData = practiceData[0].practice
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)
    }

    func showRecordingController(practices: [TKPractice], schedule: TKLessonSchedule? = nil) {
        logger.debug("当前要添加的练习数据: \(practices.toJSONString() ?? "")")
        guard let mainController = mainController else { return }
        RecordingControllerEx.toRecording(practices: practices, mainController: mainController, fatherController: self) { [weak self] returnData, totalTime, practiceId, isDone, recordController in
            guard let self = self else { return }
            UIApplication.shared.isIdleTimerDisabled = false
            self.recordController = recordController
            self.logController.tableView.isUserInteractionEnabled = true
            self.mainController?.tabBar.isHidden = false
            self.mainView.snp.updateConstraints { make in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
            self.recordController?.hide()
            if self.pageViewManager.titleView.currentIndex == 1 {
                self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 0, progress: 1)
                self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 0)
                self.pageViewManager.titleView.currentIndex = 0
                self.pageViewManager.contentView.currentIndex = 0
            }

            var index = 0
            for item in practices.enumerated() where item.element.id == practiceId {
                index = item.offset
            }
            var _returnData = returnData
            practices[index].totalTimeLength += totalTime
            var uploadData: [H5PracticeRecord] = []
            _returnData.forEachItems { item, offset in
                if item.path != "" {
                    var recordData = PracticeRecord()
                    recordData.id = item.id
                    recordData.duration = item.duration
                    recordData.startTime = Date().timeIntervalSince1970
                    recordData.format = item.path.getFileExtension
                    practices[index].recordData.append(recordData)
                    _returnData[offset].path = "log-\(item.id ?? "")\(item.path.getFileExtension)"
                    uploadData.append(_returnData[offset])
                }
            }
            if uploadData.count > 0 {
                self.upload(data: practices[index], uploadData: uploadData, practices: isDone ? [] : practices)
            } else {
                self.complete(data: practices[index], isShowLoading: true, practices: isDone ? [] : practices)
            }
        }
    }
}

extension SPracticeController {
    private func onLogForPreviewsDaysButtonTapped() {
        TKDatePicker.show(startDate: Date(seconds: 0), endDate: Date().add(component: .day, value: -1), exclude: []) { [weak self] date in
            guard let self = self else { return }
            let dateString = "\(date.year)-\(date.month)-\(date.day) 00:00:00"
            if let d = dateString.toDate("yyyy-M-d HH:mm:ss", region: .localRegion)?.date {
                currentSelectedPracticeDate = d
                self.showLog(with: d)
            }
        }
    }

    func showLog(with date: Date) {
        // 此写法为只显示作业
        // 获取当前日期的作业
        showFullScreenLoadingNoAutoHide()

        // 获取小于当天时间的最近的一次课

        // 获取当前课程布置的作业
        akasync { [weak self] in
            guard let self = self else { return }
            let practices: [TKPractice]
            if let lessonSchedule = try akawait(LessonService.lessonSchedule.getLatestLesson(beforeTime: date.timeIntervalSince1970)) {
                logger.debug("获取到的课程: \(lessonSchedule)")
                practices = try akawait(LessonService.lessonSchedule.getAssignment(withLessonId: lessonSchedule.id))
            } else {
                practices = []
            }

            DispatchQueue.main.async {
                self.hideFullScreenLoading()
                let controller = TKPopRecordPracticeController()
                controller.practiceType = .log
                controller.practiceHistoryData = []
                controller.titleString = "Log Manually"
                controller.practiceData = practices.filterDuplicates({ $0.name.trimmingCharacters(in: .whitespacesAndNewlines) })
                controller.modalPresentationStyle = .custom
                self.present(controller, animated: false, completion: nil)
                controller.confirmLog = { [weak self] in
                    guard let self = self else { return }
                    if self.pageViewManager.titleView.currentIndex == 1 {
                        self.pageViewManager.titleView.contentView(self.pageViewManager.contentView, scrollingWith: self.pageViewManager.titleView.currentIndex, targetIndex: 0, progress: 1)
                        self.pageViewManager.contentView.titleView(self.pageViewManager.titleView, didSelectAt: 0)
                        self.pageViewManager.titleView.currentIndex = 0
                        self.pageViewManager.contentView.currentIndex = 0
                    }
                }
            }
        }
    }
}
