//
//  PracticeLogController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/26.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class PracticeLogController: TKBaseViewController {
    private lazy var inviteTeacherView: TKView = {
        let view = TKView.create()
        let button = TKButton.create()
            .titleFont(font: FontUtil.medium(size: 9))
            .title(title: "INVITE")
            .backgroundColor(color: ColorUtil.red)
            .addTo(superView: view) { make in
                make.width.equalTo(42)
                make.height.equalTo(24)
                make.right.equalToSuperview().offset(-20)
                make.centerY.equalToSuperview()
            }
        button.cornerRadius = 3
        button.onTapped { [weak self] _ in
            self?.toInviteTeacher()
        }
        TKLabel.create()
            .font(font: FontUtil.regular(size: 10))
            .textColor(color: ColorUtil.Font.primary)
            .text(text: "Would you like to share your practice activities to your instructors?")
            .alignment(alignment: .left)
            .setNumberOfLines(number: 0)
            .addTo(superView: view) { make in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(20)
                make.right.equalTo(button.snp.left).offset(-20)
            }
        view.clipsToBounds = true

        return view
    }()

    var targetController: SPracticeController!
    var mainView = UIView()
    var tableView: UITableView!
    // 底部View  log  Start practice
    var bottomLayout: TKView!
    var logButton: TKBlockButton!
    var startPracticeButton: TKBlockButton!
    private var newStartPracticeButton: TKBlockButton!

    // 比现在的时间小 ,并且离我最近的课程,并且reschedule是false,并且cancellation 是false
    private var startTimestamp = 0
    private var endTimestamp = 0
    private var studentData: TKStudent!
    private var lessonTypes: TKLessonType!
    private var scheduleConfigs: [TKLessonScheduleConfigure] = []
    private var lessonSchedule: [TKLessonSchedule] = []
//    private var data: [TKLessonSchedule] = []
    private var date = Date()
    // 全部从网上获取的日程
    private var webLessonSchedule: [TKLessonSchedule] = []
    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lessonconsoleLog
    private var webLessonScheduleMap: [String: Bool] = [:]

    // 上一次加载的起始时间 previous
    private var previousCount: Int = 0
    // 上上次
    private var previousPreviousCount: Int = 0
    var isLRefresh = false
    private var assignmentData: [TKAssignment] = []
    private var df = DateFormatter()
    var practiceData: [TKPracticeAssignment] = [] {
        didSet {
            logger.debug("获取到的练习数据: \(practiceData.toJSONString() ?? "")")
            updateInviteTeacherView()
        }
    }

    private var preLessonData: TKLessonSchedule?
    private var isLoadPreAssignmenData = false
//    private var allData: [TKPracticeAssignment] = []
//    private var practiceHistoryData: [TKPractice] = []

    var addedPracticeIds: [String] = []

    override func onKeyboardShow(_ keyboardHeight: CGFloat) {
        super.onKeyboardShow(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.mainView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }, completion: nil)
    }

    override func onKeyboardHide(_ keyboardHeight: CGFloat) {
        super.onKeyboardHide(keyboardHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.mainView.transform = .identity
        }, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateInviteTeacherView()
    }

    deinit {
        EventBus.unregister(target: self)
    }

    private func initListener() {
        EventBus.listen(key: .studentInfoChanged, target: self) { [weak self] _ in
            self?.updateInviteTeacherView()
        }

        EventBus.listen(key: .studentTeacherInfoChanged, target: self) { [weak self] _ in
            self?.updateInviteTeacherView()
        }

        EventBus.listen(key: .addedPreviewsLog, target: self) { [weak self] notification in
            guard let self = self else { return }
            guard let date = notification?.object as? Date else { return }
            DispatchQueue.main.async {
                let timestamp = date.timeIntervalSince1970
                logger.debug("监听到有log数据添加,准备进行滚动: \(timestamp)")
                for (i, item) in self.practiceData.enumerated() {
                    logger.debug("检测时间, 当前item的开始时间到结束时间为: \(item.startTime) - \(item.endTime)")
                    if timestamp <= item.endTime && timestamp >= item.startTime {
                        logger.debug("当前log时间处于当前row,即将开始滚动")
                        self.tableView.scrollToRow(at: IndexPath(row: i, section: 0), at: .top, animated: true)
                        break
                    }
                }
            }
        }
    }
}

extension PracticeLogController {
    private func updateInviteTeacherView() {
        var isShow = false
        if let student = ListenerService.shared.studentData.studentData {
            if student.teacherId == "" && practiceData.count > 0 {
                isShow = true
            }
        }
        inviteTeacherView.isHidden = !isShow
        inviteTeacherView.snp.updateConstraints { make in
            make.height.equalTo(isShow ? 44 : 0)
        }
    }
}

// MARK: - View

extension PracticeLogController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor
        inviteTeacherView.addTo(superView: mainView) { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        inviteTeacherView.isHidden = true
        initTableView()
//        initbottomView()
        initListener()
    }

    func initTableView() {
        let tableViewLayout = UIView()
        tableViewLayout.backgroundColor = UIColor.white
        tableViewLayout.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        mainView.addSubview(view: tableViewLayout) { make in
            make.top.equalTo(inviteTeacherView.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }

        tableView = UITableView()
        tableViewLayout.addSubview(view: tableView) { make in
            make.edges.equalToSuperview()
        }
        drawBorder()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.white
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(PracticeLogCell.self, forCellReuseIdentifier: String(describing: PracticeLogCell.self))
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.isLRefresh = true
//            self.endTimestamp = TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .day, value: 1).startOfDay.timestamp - 1
//            self.startTimestamp = TimeUtil.endOfMonth(date: TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .month, value: -3)).timestamp
//            self.getPracticeData()
            self.targetController.endTimestamp = TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .day, value: 1).startOfDay.timestamp - 1
            self.targetController.startTimestamp = TimeUtil.changeTime(time: Double(self.startTimestamp)).add(component: .day, value: 1).startOfDay.timestamp - 1
            self.targetController.getPracticeData()
        })
        // 0652 0484
//        footer.setTitle("Drag up to refresh", for: .idle)
        footer.setTitle("", for: .idle)
        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary
        tableView.mj_footer = footer
//        tableView.isEnabled = false
        //        let header = MJRefreshNormalHeader {
//            let d = Date()
//            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
//            self.isLRefresh = false
//            self.endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
//            self.previousCount = 0
//            self.previousPreviousCount = 0
//            self.assignmentData = []
//            self.initScheduleData()
//        }
//        header.stateLabel?.font = FontUtil.regular(size: 15)
//        header.stateLabel?.textColor = ColorUtil.Font.primary
//        header.setTitle("Pull down to refresh", for: .idle)
//        header.setTitle("Release to refresh", for: .pulling)
//        header.setTitle("Loading ...", for: .refreshing)
//        header.lastUpdatedTimeLabel?.isHidden = true
//        tableView.mj_header = header
    }

    func initbottomView() {
        bottomLayout = TKView.create()
            .backgroundColor(color: UIColor.white)
            .addTo(superView: mainView, withConstraints: { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(90)
            })
        bottomLayout.setTopRadius()
        logButton = TKBlockButton(frame: CGRect.zero, title: "LOG", style: .cancel)
        bottomLayout.addSubview(view: logButton) { make in
            make.width.equalToSuperview().multipliedBy(0.4)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            make.left.equalTo(20)
        }

        startPracticeButton = TKBlockButton(frame: CGRect.zero, title: "START PRACTICE", style: .normal)
        bottomLayout.addSubview(view: startPracticeButton) { make in
            make.width.equalToSuperview().multipliedBy(0.6)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            make.right.equalToSuperview().offset(-20)
        }
        startPracticeButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.clicStartPracticeButton()
        }
        logButton.onTapped { [weak self] _ in
            guard let self = self else { return }
            self.clickLogButton()
        }
//        newStartPracticeButton = TKBlockButton(frame: .zero, title: "START PRACTICE")
//        mainView.addSubview(view: newStartPracticeButton) { make in
//            make.width.equalTo(180)
//            make.height.equalTo(50)
//            make.bottom.equalTo(-20)
//            make.centerX.equalToSuperview()
//        }
//        newStartPracticeButton.onTapped { [weak self] _ in
//            guard let self = self else { return }
//            self.clicStartPracticeButton()
//        }
    }

    private func drawBorder() {
        let layer = CALayer()
        layer.frame = CGRect(x: 10, y: 0, width: UIScreen.main.bounds.width - 20, height: 1)
        layer.backgroundColor = ColorUtil.borderColor.cgColor
        tableView.layer.addSublayer(layer)

        let path = UIBezierPath(arcCenter: CGPoint(x: 10, y: 10), radius: 10, startAngle: .pi, endAngle: .pi * (3 / 2), clockwise: true)
        path.lineWidth = 1
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        path.addArc(withCenter: CGPoint(x: UIScreen.main.bounds.width - 10, y: 10), radius: 10, startAngle: .pi * (3 / 2), endAngle: .pi * 2, clockwise: true)
        path.stroke()
        let layer2 = CAShapeLayer()
        layer2.path = path.cgPath
        layer2.strokeColor = ColorUtil.borderColor.cgColor
        layer2.fillColor = UIColor.white.cgColor
        tableView.layer.addSublayer(layer2)
    }
}

// MARK: - Data

extension PracticeLogController {
    override func initData() {
//        let d = Date()
//        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -3)).timestamp
//        endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
        df.dateFormat = "MMM d"
//        showFullScreenLoading()
//        let today = Date().startOfDay
//        var pData = TKPracticeAssignment()
//        pData.startTime = today.timeIntervalSince1970
//        pData.endTime = today.timeIntervalSince1970 + 86399
//        practiceData.append(pData)
//        allData.append(pData)
//
        ////        getStudentData()
//        getPreLesson()
//        getPracticeData()
//        EventBus.listen(EventBus.CHANGE_PRACTICE, target: self) { [weak self] _ in
//            guard let self = self else { return }
//            self.endTimestamp = d.add(component: .day, value: 1).startOfDay.timestamp - 1
//            self.startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -3)).timestamp
//            self.isLRefresh = false
//            self.isLoadPreAssignmenData = false
//            self.previousCount = 0
//            self.previousPreviousCount = 0
//            self.assignmentData = []
//            self.practiceData = []
//
//            self.practiceData.append(pData)
//            self.allData.append(pData)
//
//            self.getPracticeData()
        ////            self.initScheduleData()
//        }
    }

    func refData(data: [TKPracticeAssignment], newCount: Int) {
        logger.debug("设置练习数据: \(data.count)")
        var _data = data
        for (index, tkAssignment) in _data.enumerated() {
            var newData: [TKPractice] = []
            logger.debug("[测试Practice] => 遍历数据: index[\(index)] -> \(Date(seconds: tkAssignment.startTime).toLocalFormat("yyyy-MM-dd"))")
            for oldItem in tkAssignment.practice {
                var pos: Int = -1
                for (i, newItem) in newData.enumerated() {
                    if newItem.name == oldItem.name {
                        logger.debug("[测试Practice] => 当前newItem: \(newItem.name) | oldItem: \(oldItem.name) | 相同:\(i)")
                        pos = i
                        break
                    }
                }
                if pos == -1 {
                    if !newData.contains(where: { $0.id == oldItem.id }) {
                        newData.append(oldItem)
                    }
                } else {
                    if !addedPracticeIds.contains(oldItem.id) {
                        let newItem = newData[pos]
                        newItem.recordData += oldItem.recordData
                        newItem.totalTimeLength = newItem.totalTimeLength + oldItem.totalTimeLength
                        newData[pos] = newItem
                        addedPracticeIds.append(oldItem.id)
                    }
                }
            }
            _data[index].practice = newData.sorted(by: { i1, i2 in
                var time1: TimeInterval = 0
                var time2: TimeInterval = 0
                if let t1 = i1.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                    time1 = t1
                } else {
                    time1 = i1.startTime
                }
                if let t2 = i2.recordData.sorted(by: { $0.startTime > $1.startTime }).first?.startTime {
                    time2 = t2
                } else {
                    time2 = i2.startTime
                }
                return time1 > time2
            })
        }
        logger.debug("[测试Practice] => 整理后的数据: \(practiceData.toJSONString() ?? "")")
        logger.debug("[测试Practice] => 设置数据完成--------------------------, 整理完成的数据: \(_data.toJSONString() ?? "")")
        practiceData = _data
        if newCount > 0 {
            previousCount += 1
        }
        tableView?.mj_footer?.endRefreshing()
        if isLRefresh {
            if previousCount + previousPreviousCount == 0 {
                tableView?.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                tableView?.mj_footer?.resetNoMoreData()
            }
        } else {
            tableView?.mj_footer?.resetNoMoreData()
        }
        previousPreviousCount = previousCount
        previousCount = 0
        tableView?.reloadData()
    }

//    /// 获取上一节课
//    private func getPreLesson() {
//        addSubscribe(
//            LessonService.lessonSchedule.getPreviousLessonByStudentId(studentId: UserService.user.id()!)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
    ////                    guard docs.from == .server else { return }
//                    var data: TKLessonSchedule?
//                    for doc in docs.documents {
//                        if let doc = TKLessonSchedule.deserialize(from: doc.data()) {
//                            data = doc
//                        }
//                    }
//                    if let data = data {
//                        print("===获取到的上一节课=\(data.id)")
//                        self.preLessonData = data
//                        var addData: [TKPractice] = []
//                        var needAddData: [TKPractice] = []
//
//                        for item in self.allData {
//                            for practiceItem in item.practice where practiceItem.lessonScheduleId == data.id {
//                                addData.append(practiceItem)
//                            }
//                        }
//                        print("=======\(addData.count)===\(self.allData.count)")
//                        for addItem in addData {
//                            var isHave = false
//                            for item in self.practiceData[0].practice where addItem.id == item.id || (addItem.lessonScheduleId == item.lessonScheduleId && addItem.startTime != item.startTime && addItem.name == item.name) {
//                                isHave = true
//                            }
//                            if !isHave {
//                                let add = TKPractice()
//                                let id = "\(IDUtil.nextId(group: .audio)!)"
//                                add.id = id
//                                add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
//                                add.totalTimeLength = 0
//                                add.done = false
//                                add.recordData = []
//                                add.name = addItem.name
//                                add.studentId = addItem.studentId
//                                add.teacherId = addItem.teacherId
//                                add.assignment = true
//                                add.scheduleConfigId = addItem.scheduleConfigId
//                                add.lessonScheduleId = addItem.lessonScheduleId
//                                add.shouldDateTime = addItem.shouldDateTime
//                                add.createTime = addItem.createTime
//                                add.updateTime = addItem.updateTime
//                                self.practiceData[0].practice.append(add)
//                                needAddData.append(add)
//                            }
//                        }
//                        if needAddData.count > 0 {
//                            self.addPractices(data: needAddData)
//                        }
//
//                        self.tableView.reloadData()
//                    }
//
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }
//
//    private func getPracticeData() {
//        addSubscribe(
//            LessonService.lessonSchedule.getPracticeByStartTimeAndSId(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp), studentId: UserService.user.id()!)
//                .subscribe(onNext: { [weak self] data in
//                    guard let self = self else { return }
//                    if var data = data[.cache] {
//                        data.sort { (a, b) -> Bool in
//                            a.startTime > b.startTime
//                        }
//                        self.initShowData(data: data)
//                    }
//                    if var data = data[.server] {
//                        data.sort { (a, b) -> Bool in
//                            a.startTime > b.startTime
//                        }
//                        self.initShowData(data: data)
//                    }
//                }, onError: { [weak self] err in
//                    guard let self = self else { return }
//
//                    self.hideFullScreenLoading()
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }
//
//    private func initShowData(data: [TKPractice]) {
//        for item in data {
//            let startOfDayTime = TimeUtil.changeTime(time: item.startTime).startOfDay.timeIntervalSince1970
//            guard item.done || startOfDayTime == Date().startOfDay.timeIntervalSince1970 else { continue }
//
//            // 是不是已经有了这一天你的记录了
//            var isHave = false
//            for practiceItme in practiceData.enumerated() where practiceItme.element.startTime == startOfDayTime {
//                isHave = true
//                // 是不是已经有了practice
//                var isHavePractice = false
//                for pItem in practiceData[practiceItme.offset].practice where item.id == pItem.id {
//                    isHavePractice = true
//                }
//                if !isHavePractice {
//                    practiceData[practiceItme.offset].practice.append(item)
//                }
//            }
//            if !isHave {
//                var pData = TKPracticeAssignment()
//                pData.startTime = startOfDayTime
//                pData.endTime = startOfDayTime + 86399
//                pData.practice.append(item)
//                practiceData.append(pData)
//            }
//        }
//
//        for item in data {
//            let startOfDayTime = TimeUtil.changeTime(time: item.startTime).startOfDay.timeIntervalSince1970
//            // 是不是已经有了这一天你的记录了
//            if !item.assignment {
//                var isHave = false
//                for historyItem in practiceHistoryData where historyItem.id == item.id {
//                    isHave = true
//                }
//                if !isHave {
//                    practiceHistoryData.append(item)
//                }
//            }
//            var isHave = false
//            for practiceItme in allData.enumerated() where practiceItme.element.startTime == startOfDayTime {
//                isHave = true
//                // 是不是已经有了practice
//                var isHavePractice = false
//                for pItem in allData[practiceItme.offset].practice where item.id == pItem.id {
//                    isHavePractice = true
//                }
//                if !isHavePractice {
//                    allData[practiceItme.offset].practice.append(item)
//                }
//            }
//            if !isHave {
//                var pData = TKPracticeAssignment()
//                pData.startTime = startOfDayTime
//                pData.endTime = startOfDayTime + 86399
//                pData.practice.append(item)
//                allData.append(pData)
//            }
//        }
//
//        var needAddData: [TKPractice] = []
//        if let data = preLessonData, !isLoadPreAssignmenData {
//            var addData: [TKPractice] = []
//            for item in allData {
//                for practiceItem in item.practice where practiceItem.lessonScheduleId == data.id {
//                    addData.append(practiceItem)
//                }
//            }
//            for addItem in addData {
//                var isHave = false
//                for item in practiceData[0].practice where addItem.id == item.id || (addItem.lessonScheduleId == item.lessonScheduleId && addItem.startTime != item.startTime && addItem.name == item.name) {
//                    isHave = true
//                }
//                if !isHave {
//                    let add = TKPractice()
//                    let id = "\(IDUtil.nextId(group: .audio)!)"
//                    add.id = id
//                    add.startTime = Date().startOfDay.timeIntervalSince1970 + 10
//                    add.totalTimeLength = 0
//                    add.done = false
//                    add.recordData = []
//                    add.name = addItem.name
//                    add.studentId = addItem.studentId
//                    add.teacherId = addItem.teacherId
//                    add.assignment = true
//                    add.scheduleConfigId = addItem.scheduleConfigId
//                    add.lessonScheduleId = addItem.lessonScheduleId
//                    add.shouldDateTime = addItem.shouldDateTime
//                    add.createTime = addItem.createTime
//                    add.updateTime = addItem.updateTime
//                    practiceData[0].practice.append(add)
//                    needAddData.append(add)
//                }
//            }
//            isLoadPreAssignmenData = true
//        }
//        if needAddData.count > 0 {
//            addPractices(data: needAddData)
//        }
//        if data.count > 0 {
//            previousCount += 1
//        }
//        if tableView.mj_footer != nil {
//            tableView.mj_footer!.endRefreshing()
//            if isLRefresh {
//                if previousCount + previousPreviousCount == 0 {
//                    tableView.mj_footer!.endRefreshingWithNoMoreData()
//                } else {
//                    tableView.mj_footer!.resetNoMoreData()
//                }
//            } else {
//                tableView.mj_footer!.resetNoMoreData()
//            }
//        }
//        previousPreviousCount = previousCount
//        previousCount = 0
//        hideFullScreenLoading()
//        tableView.reloadData()
//    }

//    /// 获取学生自己的详情
//    private func getStudentData() {
//        var isLoad = false
//        addSubscribe(
//            UserService.teacher.studentGetTKStudent()
//                .subscribe(onNext: { [weak self] data in
//                    guard let self = self else { return }
//                    if let data = data[.cache] {
//                        isLoad = true
//                        self.studentData = data
//                        self.getLessonType()
//                    }
//                    if let data = data[.server] {
//                        if !isLoad {
//                            self.studentData = data
//                            self.getLessonType()
//                        }
//                    }
//                }, onError: { err in
//                    self.hideFullScreenLoading()
//                    logger.debug("获取学生信息失败:\(err)")
//                })
//        )
//    }
//
//    // 获取LessonType
//    private func getLessonType() {
//        var isLoad = false
//        addSubscribe(
//            LessonService.lessonType.getById(lessonTypeId: studentData.lessonTypeId)
//                .subscribe(onNext: { [weak self] doc in
//                    guard let self = self else { return }
//                    if isLoad {
//                        return
//                    }
//                    if doc.exists {
//                        if let data = TKLessonType.deserialize(from: doc.data()) {
//                            isLoad = true
//                            self.lessonTypes = data
//                            self.getScheduleConfig()
//                        }
//                    }
//                }, onError: { err in
//                    self.hideFullScreenLoading()
//
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }
//
//    /// 获取课程配置信息
//    private func getScheduleConfig() {
//        addSubscribe(
//            LessonService.lessonScheduleConfigure.getScheduleConfigByStudentId(studentId: studentData.studentId, teacherId: studentData.teacherId)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKLessonScheduleConfigure] = []
//                    for doc in docs.documents {
//                        if let doc = TKLessonScheduleConfigure.deserialize(from: doc.data()) {
//                            data.append(doc)
//                        }
//                    }
//                    self.scheduleConfigs = data
//                    self.initScheduleData()
//                }, onError: { err in
//                    self.hideFullScreenLoading()
//
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }
//
//    /// 整理数据
//    private func initScheduleData() {
//        guard let lessonTypes = lessonTypes else {
//            if tableView.mj_header != nil {
//                tableView.mj_header!.endRefreshing()
//            }
//            if tableView.mj_footer != nil {
//                tableView.mj_footer!.endRefreshing()
//                tableView.mj_footer!.endRefreshingWithNoMoreData()
//            }
//            return
//        }
//        tableView.mj_footer!.resetNoMoreData()
//        let sortData = ScheduleUtil.getSchedule(startTime: startTimestamp, endTime: endTimestamp, data: scheduleConfigs, lessonTypes: [lessonTypes])
//
//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: studentData.teacherId, startTime: startTimestamp, endTime: endTimestamp, isCache: true)
//                .subscribe(onNext: { docs in
//                    var data: [TKLessonSchedule] = []
//                    for doc in docs.documents {
//                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
//                            d.initShowData(lessonTypeDatas: [self.lessonTypes], lessonScheduleDatas: self.scheduleConfigs)
//                            if self.lessonScheduleIdMap[d.id] == nil {
//                                self.lessonScheduleIdMap[d.id] = d.id
//                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                    continue
//                                }
//                                self.previousCount += 1
//                                self.lessonSchedule.append(d)
//                            }
//                            data.append(d)
//                        }
//                    }
//                    for sortItem in sortData.enumerated() {
//                        let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                        sortData[sortItem.offset].id = id
//                        // 整理lesson 去除 已经存在在lessonSchedule 中的
//                        if self.lessonScheduleIdMap[id] == nil {
//                            var isCancelOfRescheduled = false
//                            for item in data where id == item.id {
//                                if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
//                                    isCancelOfRescheduled = true
//                                }
//                            }
//                            if !isCancelOfRescheduled {
//                                self.previousCount += 1
//                                self.lessonSchedule.append(sortItem.element)
//                                self.lessonScheduleIdMap[id] = id
//                            }
//                        }
//                    }
//                    self.initScheduleStudent()
//                    self.initShowData()
//                    self.previousCount = 0
//                    self.addLesson(localData: sortData)
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                    self.hideFullScreenLoading()
//
//                    for sortItem in sortData.enumerated() {
//                        let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                        sortData[sortItem.offset].id = id
//                        if self.lessonScheduleIdMap[id] == nil {
//                            self.previousCount += 1
//                            self.lessonSchedule.append(sortItem.element)
//                            self.lessonScheduleIdMap[id] = id
//                        }
//                    }
//                    self.initScheduleStudent()
//                    self.initShowData()
//                    self.previousCount = 0
//                    self.addLesson(localData: sortData)
//
//                })
//        )
//    }
//
//    private func initScheduleStudent() {
//        for item in lessonSchedule.enumerated() where lessonSchedule[item.offset].studentData == nil || lessonSchedule[item.offset].id == "" {
//            lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
//            lessonSchedule[item.offset].studentData = studentData
//        }
//    }
//
//    private func addLesson(localData: [TKLessonSchedule]) {
//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: studentData.teacherId, startTime: startTimestamp, endTime: endTimestamp)
//                .subscribe(onNext: { docs in
//                    var data: [TKLessonSchedule] = []
//                    for doc in docs.documents {
//                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
//                            d.initShowData(lessonTypeDatas: [self.lessonTypes], lessonScheduleDatas: self.scheduleConfigs)
//                            var isHave = false
//                            for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
//                                isHave = true
//                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                    self.lessonSchedule.remove(at: item.offset)
//                                } else {
//                                    self.lessonSchedule[item.offset].refreshData(newData: d)
//                                }
//                            }
//                            if !isHave {
//                                if self.lessonScheduleIdMap[d.id] == nil {
//                                    self.lessonScheduleIdMap[d.id] = d.id
//                                    if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                        continue
//                                    }
//                                    self.previousCount += 1
//                                    self.lessonSchedule.append(d)
//                                }
//                            }
//                            data.append(d)
//                        }
//                    }
//
//                    self.initScheduleStudent()
//                    self.initShowData()
//
//                }, onError: { err in
//                    self.hideFullScreenLoading()
//
//                    logger.debug("获取失败:\(err)")
//                })
//        )
//    }
//
//    /// 整理要显示的数据
//    private func initShowData() {
//        lessonSchedule.sort { (x, y) -> Bool in
//            x.shouldDateTime > y.shouldDateTime
//        }
//        print(lessonSchedule.count)
    ////        if tableView.mj_header != nil {
    ////            tableView.mj_header!.endRefreshing()
    ////        }
//        if tableView.mj_footer != nil {
//            tableView.mj_footer!.endRefreshing()
//            if isLRefresh {
//                if previousCount + previousPreviousCount == 0 {
//                    tableView.mj_footer!.endRefreshingWithNoMoreData()
//                } else {
//                    tableView.mj_footer!.resetNoMoreData()
//                }
//            } else {
//                tableView.mj_footer!.resetNoMoreData()
//            }
//        }
//        previousPreviousCount = previousCount
//        getPractice()
//    }
//
//    private func getPractice() {
//        // 根据获取到的课程 , 然后在去数据库中查询该课程是否有作业,
//        print("===\(startTimestamp)====\(endTimestamp)")
//        addSubscribe(
//            LessonService.lessonSchedule.getAssignmentByStudentIdAndInTime(studentId: studentData.studentId, startTime: startTimestamp, endTime: endTimestamp)
//                .subscribe(onNext: { [weak self] data in
//                    guard let self = self else { return }
//                    if data.documents.count > 0 {
//                        for item in data.documents {
//                            if let d = TKAssignment.deserialize(from: item.data()) {
//                                var isHave = false
//                                for item in self.assignmentData where d.id == item.id {
//                                    isHave = true
//                                }
//                                if !isHave {
//                                    self.assignmentData.append(d)
//                                }
//                            }
//                        }
//                    }
//                    print("获取到的课程个数:\(data.documents.count)==\(self.assignmentData.count)")
//
//                    self.initPracticeData()
//
//                }, onError: { err in
//                    self.hideFullScreenLoading()
//
//                    logger.debug("======\(err)")
//                })
//        )
//    }
//
//    private func initPracticeData() {
//        hideFullScreenLoading()
//
//        data.removeAll()
//        for schedule in lessonSchedule.enumerated().reversed() {
//            lessonSchedule[schedule.offset].assignmentData = []
//            if schedule.element.shouldDateTime > Double(date.timestamp) {
//                lessonSchedule.remove(at: schedule.offset)
//            }
//        }
    ////        for item in lessonSchedule.enumerated().reversed() where item.element.shouldDateTime > Double(date.timestamp){
    ////                 lessonSchedule.remove(at: item.offset)
    ////             }
//
    ////        var totalTimeLength: CGFloat = 0
    ////        for item in assignment {
    ////            let mapId = "\(item.studentId)"
    ////            totalTimeLength += item.timeLength
    ////            var timeLength: CGFloat = (item.timeLength / 60 / 60).roundTo(places: 1)
    ////            if timeLength > 0 {
    ////                if timeLength < 0.1 {
    ////                    timeLength = 0.1
    ////                }
    ////            }
    ////            if studentMap[mapId] != nil {
    ////                studentMap[mapId]! += timeLength
    ////            } else {
    ////                studentMap[mapId] = timeLength
    ////            }
    ////        }
    ////        getStudentList()
    ////        totalTimeLength = (totalTimeLength / 60 / 60 / 7).roundTo(places: 1)
    ////        if totalTimeLength > 0 {
    ////            if totalTimeLength < 0.1 {
    ////                totalTimeLength = 0.1
    ////            }
    ////            practiceLabel.text("\(totalTimeLength)")
    ////        } else {
    ////            practiceLabel.text("0")
    ////        }
//
//        assignmentData.sort { (a, b) -> Bool in
//            a.done && a.createTime > b.createTime
//        }
//        for item in assignmentData {
//            for schedule in lessonSchedule.enumerated() where item.lessonScheduleId == schedule.element.id {
//                lessonSchedule[schedule.offset].assignmentData.append(item)
//            }
//        }
//        for schedule in lessonSchedule.enumerated() {
//            if schedule.element.assignmentData.count > 0 || schedule.offset == 0 {
//                data.append(schedule.element)
//            }
//        }
//        tableView.reloadData()
//    }

    private func addPractices(data: [TKPractice]) {
        addSubscribe(
            LessonService.lessonSchedule.addPractices(data: data)
                .subscribe(onNext: { _ in
                    logger.debug("====add成功==")

                }, onError: { err in
                    logger.debug("====add失败==\(err)")
                })
        )
    }
}

// MARK: - TableView

extension PracticeLogController: UITableViewDelegate, UITableViewDataSource, PracticeLogCellDelegate, PlayAudiodControllerDelegate {
    func playAudiodController(deleteIndex: [Int], storagePath: [String], indexPath: IndexPath) {
        // MARK: - 删除录音需要修改

        logger.debug("记录录音数据")
        var deleteIndex = deleteIndex
        if deleteIndex.count > 0 {
            deleteIndex.sort { (a, b) -> Bool in
                a > b
            }
            for item in deleteIndex {
                practiceData[indexPath.section].practice[indexPath.row].recordData.remove(at: item)
            }
            tableView.reloadRows(at: [IndexPath(row: indexPath.section, section: 0)], with: .none)
            addSubscribe(
                LessonService.lessonSchedule.updatePractice(id: practiceData[indexPath.section].practice[indexPath.row].id, data: ["recordData": practiceData[indexPath.section].practice[indexPath.row].recordData.toJSON()])
                    .subscribe(onNext: { _ in
                        print("删除更新成功")
                        //                        "/practice/\(data.recordIds[index])\(data.recordFormats[index])"
                        for item in storagePath {
                            StorageService.shared.deleteFileNoReturn(path: item)
                        }
                    }, onError: { err in
                        logger.debug("获取失败:\(err)")
                    })
            )
        }
    }

    func practiceLogCell(clickAddLog cell: PracticeLogCell) {
        clickLogButton()
    }

    func practiceLogCell(clickPlay index: Int, cell: PracticeLogCell, practice: TKPractice) {
//        let data = practiceData[cell.tag].practice[index]
        let controller = TKPracticeRecordingListViewController(practice, style: .studentView)
        controller.modalPresentationStyle = .custom
        present(controller, animated: true, completion: nil)
        
//        let controller = PlayAudiodController()
//        controller.isEdit = true
//        controller.indexPath = IndexPath(row: index, section: cell.tag)
//        controller.data = practiceData[cell.tag].practice[index]
//        controller.modalPresentationStyle = .custom
//        controller.delegate = self
//        present(controller, animated: false, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return practiceData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PracticeLogCell.self), for: indexPath) as! PracticeLogCell
        cell.df = df
        cell.delegate = self
        cell.tag = indexPath.row
        cell.initData(data: practiceData[indexPath.row])
        return cell
    }
}

// MARK: - Action

extension PracticeLogController {
    func clicStartPracticeButton() {
//        guard lessonSchedule.count > 0 else {
//            return
//        }
//        tableView.isUserInteractionEnabled = false
//
//        let schedule = lessonSchedule[0].copy()
//        let controller = TKPopRecordPracticeController()
//        controller.practiceType = .practice
//        controller.titleString = "Practice"
//        controller.schedule = schedule
//        controller.confirmAction = { [weak self] practices in
//            guard let self = self else { return }
        ////            RecordingControllerEx.toRecording(assignment: practices, fatherController: self)
//            self.targetController?.showRecordingController(assignment: practices, schedule: schedule)
//        }
//        controller.modalPresentationStyle = .custom
//        present(controller, animated: false, completion: nil)
        guard practiceData.count > 0 else {
            return
        }

        practiceData[0].practice.forEachItems { item, _ in
            for hItem in targetController.practiceHistoryData.enumerated().reversed() where hItem.element.name == item.name {
                targetController.practiceHistoryData.remove(at: hItem.offset)
            }
        }

        let controller = TKPopRecordPracticeController()
        controller.practiceType = .practice
        controller.practiceHistoryData = targetController.practiceHistoryData
        controller.titleString = "Record Practice"
        controller.practiceData = targetController.practiceData[0].practice
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
        controller.confirmAction = { [weak self] practices in
            guard let self = self else { return }
            self.targetController?.showRecordingController(practices: practices)
        }

//        targetController?.showRecordingController(assignment: [], schedule: nil)
    }

    func clickLogButton() {
        practiceData[0].practice.forEachItems { item, _ in
            for hItem in targetController.practiceHistoryData.enumerated().reversed() where hItem.element.name == item.name {
                targetController.practiceHistoryData.remove(at: hItem.offset)
            }
        }

        let controller = TKPopRecordPracticeController()
        controller.practiceType = .log
        controller.practiceHistoryData = targetController.practiceHistoryData
        controller.titleString = "Log Manually"
        controller.practiceData = targetController.practiceData[0].practice
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}

extension PracticeLogController: SInviteTeacherViewControllerDelegate {
    func sInviteTeacherViewControllerDismissed() {
    }

    func toInviteTeacher() {
        let controller = SInviteTeacherViewController()
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        present(controller, animated: false, completion: nil)
    }
}
