//
//  AllFuturesController.swift
//  TuneKey
//
//  Created by wht on 2020/4/20.
//  Copyright © 2020 spelist. All rights reserved.
//

import DZNEmptyDataSet
import FirebaseFirestore
import MJRefresh
import SnapKit
import UIKit

class AllFuturesController: TKBaseViewController {
    struct Module {
        enum `Type`: String {
            case lesson = "Lesson"
            case studioEvents = "Event"
        }

        var type: Type
        var lesson: TKLessonSchedule?
        var event: StudioEvent?
    }

    private var mainView = UIView()
    private var navigationBar: TKNormalNavigationBar!
    private var tableView: UITableView!
    private var startTimestamp = 0
    private var endTimestamp = 0

    var studentData: TKStudent!
    var lessonTypes: [TKLessonType] = []
    var scheduleConfigs: [TKLessonScheduleConfigure] = []
    private var lessonSchedule: [TKLessonSchedule] = [] {
        didSet {
            resetModules()
        }
    }

    private var locationInfos: [String: String] = [:]

    private var studioEvents: [StudioEvent] = [] {
        didSet {
            resetModules()
        }
    }

    private var modules: [Module] = []

    // 全部从网上获取的日程
    private var webLessonSchedule: [TKLessonSchedule] = []
    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lesson
    private var webLessonScheduleMap: [String: Bool] = [:]
    // 上一次加载的起始时间 previous
    private var previousCount: Int = 0
    // 上上次
    private var previousPreviousCount: Int = 0
    private var isLRefresh = false
    private var policyData: TKPolicies!
    private var opendIndex: Int! = -1 // 正在展开的Cell
    private var cancelData: [TKLessonCancellation]!
    private var rescheduleData: [TKReschedule]!
    private var df: DateFormatter!
    var delegate: AllFuturesControllerDelegate?

    private var followUps: [TKFollowUp] = []

    private var isDataLoaded: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }

    deinit {
        logger.debug("销毁Upcoming页")
    }

    private func resetModules() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.modules = self.lessonSchedule.filterDuplicates({ $0.id }).compactMap({ Module(type: .lesson, lesson: $0) }) + self.studioEvents.compactMap({ Module(type: .studioEvents, event: $0) })
            self.modules = self.modules.sorted(by: { self.getTime(fromModule: $0) < self.getTime(fromModule: $1) })
            logger.debug("当前要显示的数据量：\(self.modules.count) | \(self.lessonSchedule.count) | \(self.lessonSchedule.compactMap({ $0.id }))")
            self.tableView?.reloadData()
        }
    }

    private func getTime(fromModule module: Module) -> TimeInterval {
        switch module.type {
        case .lesson: return module.lesson?.getShouldDateTime() ?? 0
        case .studioEvents: return module.event?.startTime ?? 0
        }
    }
}

// MARK: - View

extension AllFuturesController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Upcoming", rightButton: "ADD LESSON", target: self, onRightButtonTapped: { [weak self] in
            self?.onAddLessonTapped()
        })
        mainView.addSubviews(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initTableView()
    }

    func initTableView() {
        tableView = UITableView()
        mainView.addSubview(view: tableView) { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
        }
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.emptyDataSetSource = self
        tableView.register(AllFuturesCell.self, forCellReuseIdentifier: String(describing: AllFuturesCell.self))
        tableView.register(UpcomingStudioEventsTableViewCell.self, forCellReuseIdentifier: UpcomingStudioEventsTableViewCell.id)

        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.isLRefresh = true
            self.endTimestamp = TimeUtil.changeTime(time: Double(self.endTimestamp)).add(component: .month, value: 3).timestamp
            SL.Executor.runAsync { [weak self] in
                self?.initScheduleData()
            }
        })
//        footer.setTitle("Drag up to refresh", for: .idle)
        footer.setTitle("", for: .idle)

        footer.setTitle("Loading more...", for: .refreshing)
        footer.setTitle("No more lessons", for: .noMoreData)
        footer.stateLabel?.font = FontUtil.regular(size: 15)
        footer.stateLabel?.textColor = ColorUtil.Font.primary
        tableView.mj_footer = footer
    }
}

// MARK: - Data

extension AllFuturesController {
    override func initData() {
        super.initData()
        df = DateFormatter()
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm, MMM d"
        let d = Date()
        startTimestamp = d.startOfDay.timestamp
        endTimestamp = d.add(component: .month, value: 3).startOfDay.timestamp - 1
//        showFullScreenLoading()
        navigationBar?.startLoading()
        if studentData != nil {
            logger.debug("开始获取数据")
            getCancelLessonData()
            getReschedule()
            getPolicies()
            getScheduleConfig()
            initScheduleData()
            loadStudioEvents()
        }

        EventBus.listen(EventBus.REFRESH_STUDENT_UPCOMING_LIST, target: self) { [weak self] data in
            guard let self = self, let data = data?.object as? TKStudent else { return }
            print("======?")
            self.studentData = data
            self.getScheduleConfig()
        }

        EventBus.listen(key: .studentConfigChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            if self.studentData != nil {
                let d = Date()
                self.startTimestamp = d.startOfDay.timestamp
                self.endTimestamp = d.add(component: .month, value: 3).startOfDay.timestamp - 1
                self.lessonSchedule = []
                self.lessonScheduleIdMap.removeAll()
                self.getScheduleConfig()
                self.getCancelLessonData()
                self.getReschedule()
                self.initScheduleData()
                self.loadStudioEvents()
            }
        }

        EventBus.listen(EventBus.CHANGE_SCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            if self.studentData != nil {
                self.getScheduleConfig()
                self.getCancelLessonData()
                self.getReschedule()
                self.initScheduleData()
                self.loadStudioEvents()
            }
        }
        EventBus.listen(EventBus.CHANGE_RESCHEDULE, target: self) { [weak self] _ in
            guard let self = self else { return }
            if self.studentData != nil {
                self.getCancelLessonData()
                self.getReschedule()
                self.initScheduleData()
                self.loadStudioEvents()
            }
        }

        EventBus.listen(key: .studentTeacherChanged, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.lessonSchedule = []
            self.tableView.reloadData()
            self.initData()
        }
    }

    private func loadData() {
        guard !isDataLoaded else { return }
        isDataLoaded = true
        df = DateFormatter()
        df.dateFormat = Locale.is12HoursFormat() ? "hh:mm a, MMM d" : "HH:mm, MMM d"
        let d = Date()
        startTimestamp = d.startOfDay.timestamp
        endTimestamp = d.add(component: .month, value: 3).startOfDay.timestamp - 1
//        showFullScreenLoading()
        guard let studentData = studentData else { return }
        navigationBar?.startLoading()
        akasync { [weak self] in
            guard let self = self else { return }
            self.followUps = try akawait(StudentService.upcoming.getFollowUps(withStudioId: studentData.studioId, studentId: studentData.studentId))
            self.scheduleConfigs = try akawait(StudentService.upcoming.getLessonScheduleConfigs(withStudioId: studentData.studioId, studentId: studentData.studentId))
            self.lessonSchedule = try akawait(StudentService.lessons.getLessonSchedule(withStudentId: studentData.studentId, studioId: studentData.studioId, dateTimeRange: DateTimeRange(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp))))
            updateUI {
                for (_, lesson) in self.lessonSchedule.enumerated() {
                    if self.lessonScheduleIdMap[lesson.id] == nil {
                        self.lessonScheduleIdMap[lesson.id] = lesson.id
                        self.previousCount += 1
                    }
                }
                self.initScheduleStudent()
                self.initShowData()
                self.tableView.reloadData()
                self.navigationBar?.stopLoading()
            }
        }
//        if studentData != nil {
//            logger.debug("开始获取数据")
//            getCancelLessonData()
//            getReschedule()
//            getPolicies()
//            getScheduleConfig()
//            initScheduleData()
//        }
    }

    /// 获取课程配置信息
    private func getScheduleConfig() {
        scheduleConfigs = ListenerService.shared.studentData.scheduleConfigs
    }

    private func getLessonType(ids: [String]) {
        LessonService.lessonType.getByIds(ids: ids)
            .done { [weak self] lessonTypes in
                guard let self = self else { return }
                self.lessonTypes = lessonTypes
                self.getCancelLessonData()
                self.getReschedule()
                self.getPolicies()
                self.initScheduleData()
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                logger.debug("获取失败:\(error)")
                self.getCancelLessonData()
                self.getReschedule()
                self.getPolicies()
                self.initScheduleData()
            }

//        var isLoad = false
//        addSubscribe(
//            LessonService.lessonType.getByIds(ids: ids)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    if isLoad {
//                        return
//                    }
//                    var data: [TKLessonType] = []
//                    for doc in docs.documents {
//                        if let doc = TKLessonType.deserialize(from: doc.data()) {
//                            data.append(doc)
//                        }
//                    }
//                    self.lessonTypes = data
//                    if data.count > 0 {
//                        isLoad = true
//                    }
//
//                    self.getCancelLessonData()
//                    self.getReschedule()
//                    self.getPolicies()
//                    self.initScheduleData()
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                    self.getCancelLessonData()
//                    self.getReschedule()
//                    self.getPolicies()
//                    self.initScheduleData()
//                })
//        )
    }

    private func getStudentData() {
        var isLoad = false
        addSubscribe(
            UserService.teacher.studentGetTKStudent()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }

                    if let data = data[.server] {
                        if !isLoad {
                            self.studentData = data
                            self.getCancelLessonData()
                            self.getReschedule()
                            self.getPolicies()
                            self.initScheduleData()
                        }
                    }

                    if let data = data[.cache] {
                        self.studentData = data
                        isLoad = true
                        print("=====走到了这里面")
                        self.getCancelLessonData()
                        self.getReschedule()
                        self.getPolicies()
                        self.initScheduleData()
                    }
                }, onError: { err in
                    logger.debug("获取学生信息失败:\(err)")
                })
        )
    }

    private func getReschedule() {
        addSubscribe(
            LessonService.lessonSchedule.getRescheduleByStudentId(sId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    print("=我开始刷新==个数=\(data.count)")
                    self.rescheduleData = data
                    for item in self.lessonSchedule.enumerated() where item.element.rescheduled {
                        for data in self.rescheduleData where data.scheduleId == item.element.id {
                            self.lessonSchedule[item.offset].rescheduleLessonData = data
                        }
                    }
                }, onError: { [weak self] err in
                    self?.rescheduleData = []
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getPolicies() {
        guard studentData.teacherId != "" else {
            hideFullScreenLoading()
            return
        }
        addSubscribe(
            UserService.teacher.getPoliciesById(policiesId: studentData.teacherId)
                .subscribe(onNext: { [weak self] doc in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if doc.exists {
                        if let data = TKPolicies.deserialize(from: doc.data()) {
                            self.policyData = data
                        }
                    }

                }, onError: { [weak self] err in
                    self?.hideFullScreenLoading()

                    logger.debug("======\(err)")
                })
        )
    }

    private func getCancelLessonData() {
        addSubscribe(
            LessonService.lessonSchedule.studentGetCancellationListByStudentId(studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonCancellation] = []
                    for doc in docs.documents {
                        if let doc = TKLessonCancellation.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    self.cancelData = data
                    for item in self.lessonSchedule.enumerated() where item.element.cancelled {
                        for data in self.cancelData where data.oldScheduleId == item.element.id {
                            self.lessonSchedule[item.offset].cancelLessonData = data
                        }
                    }
                }, onError: { [weak self] err in
                    self?.cancelData = []
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// 整理数据
    private func initScheduleData() {
        logger.debug("开始刷新课程")
//        addLesson(localData: [])
        guard lessonTypes.count > 0 else {
            logger.debug("当前课程没有lessonType,返回")
            tableView.mj_header?.endRefreshing()
            tableView.mj_footer?.endRefreshing()
            tableView.mj_footer?.endRefreshingWithNoMoreData()
            navigationBar?.stopLoading()
            return
        }
        tableView.mj_footer!.resetNoMoreData()
        LessonService.lessonSchedule.studentRefreshLessonSchedule(config: scheduleConfigs, lessonTypes: lessonTypes, startTime: startTimestamp, endTime: endTimestamp)
            .done { [weak self] _ in
                guard let self = self else { return }
                self.addLesson(localData: [])
            }
            .catch { error in
                logger.error("刷新课程失败: \(error)")
            }

//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: studentData.teacherId, startTime: startTimestamp, endTime: endTimestamp, isCache: true)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKLessonSchedule] = []
//                    for doc in docs.documents {
//                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
//                            guard self.scheduleConfigs.contains(where: { ($0.id == d.lessonScheduleConfigId) }) else { continue }
//                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                            if self.lessonScheduleIdMap[d.id] == nil {
//                                self.lessonScheduleIdMap[d.id] = d.id
//                                print("1====\(d.id)")
        ////                                if d.rescheduled && d.rescheduleId != "" {
        ////                                    continue
        ////                                }
//                                self.previousCount += 1
//                                self.lessonSchedule.append(d)
//                            }
//                            data.append(d)
//                        }
//                    }
//
//                    for sortItem in sortData.enumerated() {
//                        let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                        sortData[sortItem.offset].id = id
//                        print("=2===\(id)")
//
//                        // 整理lesson 去除 已经存在在lessonSchedule 中的
//                        if self.lessonScheduleIdMap[id] == nil {
        ////                            var isCancelOfRescheduled = false
        ////                            for item in data where id == item.id {
        ////                                if item.rescheduled && item.rescheduleId != "" {
        ////                                    isCancelOfRescheduled = true
        ////                                }
        ////                            }
        ////                            if !isCancelOfRescheduled {
//                            self.lessonScheduleIdMap[id] = id
//
//                            self.previousCount += 1
//                            self.lessonSchedule.append(sortItem.element)
        ////                            }
//                        }
//                    }
//                    self.initScheduleStudent()
//                    self.initShowData()
//                    self.previousCount = 0
//
//                    self.addLesson(localData: sortData)
//
//                }, onError: { [weak self] err in
//                    guard let self = self else { return }
//                    logger.debug("获取失败:\(err)")
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
    }

    private func initScheduleStudent() {
//        for item in lessonSchedule.enumerated() where lessonSchedule[item.offset].studentData == nil || lessonSchedule[item.offset].id == "" {
//            lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
//            lessonSchedule[item.offset].studentData = studentData
//        }
    }

    private func addLesson(localData: [TKLessonSchedule]) {
        logger.debug("开始获取新课程: \(studentData.studentId) | \(studentData.teacherId) | \(startTimestamp) | \(endTimestamp)")
        navigationBar?.startLoading()
        StudentService.lessons.getLessonSchedule(withStudentId: studentData.studentId, studioId: studentData.studioId, dateTimeRange: DateTimeRange(startTime: TimeInterval(startTimestamp), endTime: TimeInterval(endTimestamp)))
            .done { [weak self] lessonSchedules in
                guard let self = self else { return }
                logger.debug("[课程获取] => 获取到的课程数量: \(lessonSchedules.count)")
                var data: [TKLessonSchedule] = []
                var lessonSchedule = self.lessonSchedule
                for d in lessonSchedules {
                    guard self.scheduleConfigs.contains(where: { $0.id == d.lessonScheduleConfigId }) else { continue }
                    d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                    var isHave = false
                    for item in lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                        isHave = true
                        lessonSchedule[item.offset].refreshData(newData: d)
                    }
                    if !isHave {
                        if self.lessonScheduleIdMap[d.id] == nil {
                            self.lessonScheduleIdMap[d.id] = d.id
                            self.previousCount += 1
                            lessonSchedule.append(d)
                        }
                    }
                    data.append(d)
                }
                logger.debug("[课程获取] => 处理完的课程数量: \(lessonSchedules.count)")
                self.lessonSchedule = lessonSchedule
                self.initScheduleStudent()
                self.initShowData()
            }
            .catch { error in
                logger.error("获取失败： \(error)")
            }
//        var teacherId: String = studentData.teacherId
//        if studentData.studentApplyStatus == .apply {
//            teacherId = ""
//        }
//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleListByStudentId(studentId: studentData.studentId, teacherID: teacherId, startTime: startTimestamp, endTime: endTimestamp)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    self.navigationBar?.stopLoading()
//                    logger.debug("获取到的数量: \(docs.count)")
//                    var data: [TKLessonSchedule] = []
//                    for doc in docs.documents {
//                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
//                            guard self.scheduleConfigs.contains(where: { $0.id == d.lessonScheduleConfigId }) else { continue }
//                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                            var isHave = false
//                            for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
//                                isHave = true
        ////                                if d.rescheduled && d.rescheduleId != "" {
        ////                                    self.lessonSchedule.remove(at: item.offset)
        ////                                } else {
//                                self.lessonSchedule[item.offset].refreshData(newData: d)
        ////                                }
//                            }
//                            if !isHave {
//                                if self.lessonScheduleIdMap[d.id] == nil {
//                                    self.lessonScheduleIdMap[d.id] = d.id
        ////                                    if d.rescheduled && d.rescheduleId != "" {
        ////                                        continue
        ////                                    }
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
        ////                    self.initLesson(addData: localData, lessonSchedule: data)
//
//                }, onError: { err in
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    private func initLesson(addData: [TKLessonSchedule], lessonSchedule: [TKLessonSchedule]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var lessonSchedule = lessonSchedule
            lessonSchedule.sort { a, b -> Bool in
                a.shouldDateTime > b.shouldDateTime
            }

            for item in lessonSchedule {
                let id = "\(item.teacherId):\(item.studentId):\(Int(item.shouldDateTime))"
                if self.webLessonScheduleMap[id] == nil {
                    self.webLessonSchedule.append(item)
                    self.webLessonScheduleMap[id] = true
                }
            }
            var addLessonData: [TKLessonSchedule] = []
            for item in addData where self.webLessonScheduleMap["\(item.teacherId):\(item.studentId):\(Int(item.shouldDateTime))"] == nil && item.type == .lesson {
                addLessonData.append(item)
            }
//            self.addLessonSchedules(lessonSchedule: addLessonData)
        }
    }

    /// 把需要添加的数据添加到网上
    /// - Parameter lessonSchedule: 需要添加的数据
    private func addLessonSchedules(lessonSchedule: [TKLessonSchedule]) {
        logger.debug("需要Add的数据:\(lessonSchedule.toJSONString(prettyPrint: true) ?? "")")
        if lessonSchedule.count == 0 {
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.addLessonSchedules(schedules: lessonSchedule)
                .subscribe(onNext: { data in
                    logger.debug("======addLessonSchedules成功了?:\(data)")
                }, onError: { err in
                    logger.debug("======addLessonSchedules失败了?:\(err)")
                })
        )
    }

    /// 整理要显示的数据
    private func initShowData() {
        lessonSchedule.sort { x, y -> Bool in
            x.shouldDateTime < y.shouldDateTime
        }
        let nowTime = Date().timestamp
        for item in lessonSchedule.enumerated().reversed() {
            if Int(item.element.getShouldDateTime()) < nowTime {
                lessonSchedule.remove(at: item.offset)
            } else {
                if item.element.cancelled {
                    for data in cancelData where data.oldScheduleId == item.element.id {
                        lessonSchedule[item.offset].cancelLessonData = data
                    }
                }
                if item.element.rescheduled {
                    for data in rescheduleData where data.scheduleId == item.element.id {
                        lessonSchedule[item.offset].rescheduleLessonData = data
                    }
                }
                if let config = self.scheduleConfigs.first(where: { $0.id == item.element.lessonScheduleConfigId }) {
                    if config.endType == .endAtSomeday && config.endDate < item.element.getShouldDateTime() {
                        lessonSchedule.remove(at: item.offset)
                    }
                }
            }
        }
        logger.debug("[课程获取] => 二次处理完的课程数量: \(lessonSchedule.count)")
        resetModules()
        if tableView.mj_footer != nil {
            tableView.mj_footer!.endRefreshing()
            if isLRefresh {
                if previousCount + previousPreviousCount == 0 {
                    tableView.mj_footer!.endRefreshingWithNoMoreData()
                } else {
                    tableView.mj_footer!.resetNoMoreData()
                }
            } else {
                tableView.mj_footer!.resetNoMoreData()
            }
        }
        initLocationData()
        tableView.reloadData()
        previousPreviousCount = previousCount
        navigationBar.stopLoading()
    }

    private func initLocationData() {
        guard lessonSchedule.isNotEmpty else { return }
        for lessonScheduleItem in lessonSchedule {
            var locationItem: TKLocation?
            if let location = lessonScheduleItem.location, !location.isNone {
                locationItem = location
            } else if let config = scheduleConfigs.first(where: { $0.id == lessonScheduleItem.lessonScheduleConfigId }) {
                locationItem = config.location
            }

            if let locationItem {
                var locationInfo: String = ""
                switch locationItem.type {
                case .remote:
                    locationInfo = "Online: \(locationItem.remoteLink)"
                case .studioRoom:
                    var id: String = ""
                    if locationItem.place.isNotEmpty {
                        id = locationItem.place
                    } else if locationItem.id.isNotEmpty {
                        id = locationItem.id
                    }

                    if id.isNotEmpty, let room = ListenerService.shared.studentData.studioRooms.first(where: { $0.id == id }) {
                        locationInfo = "Location: \(room.name)"
                    }
                case .otherPlace, .studioLocation, .studentHome:
                    locationInfo = "Location: \(locationItem.place)"
                }
                if locationInfo.isNotEmpty {
                    locationInfos[lessonScheduleItem.id] = locationInfo
                }
            }
        }
    }

    private func addCancellation(type: Int, schedule: TKLessonSchedule, rescheduleId: String?, isReschedule: Bool = false, cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        // 1:不退款也不可以makeup 2:Makeup 3:退款
        showFullScreenLoading()
        let time = "\(Date().timestamp)"
        let cancellationData = TKLessonCancellation()
        var sendType = 0
        cancellationData.id = schedule.id
        cancellationData.oldScheduleId = schedule.id
        if type == 1 {
            cancellationData.type = .noRefundAndMakeup
            sendType = -1
        } else if type == 2 {
            cancellationData.type = .noNewSchedule
            sendType = 0
        } else {
            cancellationData.type = .refund
            sendType = 2
        }
        cancellationData.studentId = schedule.studentId
        cancellationData.teacherId = schedule.teacherId

        // MARK: - TimeBefore 要修改的地方

        cancellationData.timeBefore = "\(schedule.shouldDateTime)"
        cancellationData.createTime = time
        cancellationData.updateTime = time
        if !isReschedule {
            addSubscribe(
                LessonService.lessonSchedule.cancelSchedule(data: cancellationData)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        sendHis()
                        CommonsService.shared.sendEmailToTeacherForCancellation(studentName: self.studentData.name, lessonStartTime: Int(schedule.getShouldDateTime()), teacherId: schedule.teacherId, type: sendType)
//                        self.dismiss(animated: true) {
//                            TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
//                        }
                        TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        lesson.cancelled = true
                        self.tableView.reloadRows(at: [IndexPath(row: cell.tag, section: 0)], with: .none)
                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
        } else {
            guard let rescheduleId = rescheduleId else {
                hideFullScreenLoading()
                TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                return
            }
            addSubscribe(
                LessonService.lessonSchedule.cancelSchedule(data: cancellationData, rescheduleId: rescheduleId)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        sendHis()
                        CommonsService.shared.sendEmailToTeacherForCancellation(studentName: self.studentData.name, lessonStartTime: Int(schedule.getShouldDateTime()), teacherId: schedule.teacherId, type: sendType)

//                        self.dismiss(animated: true) {
//                            TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
//                        }
                        TKToast.show(msg: TipMsg.cancellationSuccessful, style: .success)
                        lesson.cancelled = true
                        self.tableView.reloadRows(at: [IndexPath(row: cell.tag, section: 0)], with: .none)
                    }, onError: { [weak self] err in
                        self?.hideFullScreenLoading()
                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                        logger.debug("获取失败:\(err)")
                    })
            )
        }

        func sendHis() {
            if type != 1 {
                let time = "\(Date().timestamp)"

                let his = TKRescheduleMakeupRefundHistory()

                his.updateTime = time
                his.createTime = time
                his.id = time
                if let id = IDUtil.nextId(group: .lesson) {
                    his.id = "\(id)"
                }
                his.teacherId = schedule.teacherId
                his.studentId = schedule.studentId
                if type == 2 {
                    his.type = .makeup
                } else {
                    his.type = .refund
                }
                UserService.teacher.setRescheduleMakeupRefundHistory(data: his)
            }
        }
    }

    private func loadStudioEvents() {
        guard let studioId = ListenerService.shared.studentData.teacherData?.studioId else { return }
        DatabaseService.collections.studioEvents()
            .whereField("studioId", isEqualTo: studioId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    logger.error("获取events失败: \(error)")
                } else {
                    if let events: [StudioEvent] = [StudioEvent].deserialize(from: snapshot?.documents.compactMap({ $0.data() })) as? [StudioEvent] {
                        let now = Date().timeIntervalSince1970
                        self.studioEvents = events.filter({ $0.startTime >= now || (($0.endTime == 0 || $0.endTime > now) && $0.startTime <= now) })
                    } else {
                        self.studioEvents = []
                    }
                }
            }
    }
}

// MARK: - TableView

extension AllFuturesController: UITableViewDelegate, UITableViewDataSource, AllFuturesCellDelegate {
    func allFuturesCellSchedule(clickCell cell: AllFuturesCell, isLeft: Bool) {
        if isLeft {
            clickLeftCell(cell)
        } else {
            clickRightCell(cell)
        }
    }

    func clickRightCell(_ cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        var endTime = Date().timeIntervalSince1970
        if cell.tag != lessonSchedule.count - 1 {
            var newData: [TKLessonSchedule] = []
            var pos = 0
            for item in lessonSchedule where !item.cancelled && !(item.rescheduled && item.rescheduleId != "") {
                if item.id == lesson.id {
                    pos = newData.count
                }
                newData.append(item)
            }
            if pos != lessonSchedule.count - 1 {
                if (pos + 1) <= newData.count - 1 {
                    endTime = newData[pos + 1].shouldDateTime
                }
            }
        }
        guard !lesson.cancelled && !(lesson.rescheduled && lesson.rescheduleId != "") else {
            return
        }
        let controller = SLessonDetailsController(lessonSchedule: lesson)
        controller.modalPresentationStyle = .fullScreen
        controller.isLoadoadPracticeData = true
        controller.endTime = endTime
        controller.hero.isEnabled = true
        controller.enablePanToDismiss()
        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
        present(controller, animated: true, completion: nil)
    }

    func clickLeftCell(_ cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        guard !(lesson.rescheduled && lesson.rescheduleId != "") else { return }

        let data = lesson
        if data.teacherId == "" {
            // 当前未绑定任何教师,显示删除按钮
            tableView.beginUpdates()
            if cell.rescheduleButton.isHidden {
                cell.rescheduleButton.isHidden = false
                cell.cancelButton.isHidden = false
                cell.mainView.snp.updateConstraints { make in
                    make.height.equalTo(146)
                }
            } else {
                cell.rescheduleButton.isHidden = true
                cell.cancelButton.isHidden = true
                cell.mainView.snp.updateConstraints { make in
                    make.height.equalTo(96)
                }
            }

            tableView.endUpdates()

        } else {
            if lesson.rescheduled && lesson.rescheduleId == "" {
                dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.allFuturesController(clickPendingLesson: lesson.id)
                }
            } else {
                if policyData != nil {
                    tableView.beginUpdates()
                    if lesson.cancelled && !lesson.rescheduled {
                        if cell.makeUpButton.isHidden {
                            cell.makeUpButton.isHidden = false
                            cell.line.isHidden = false
                            lesson._isOpen = true
                            cell.mainView.snp.updateConstraints { make in
                                make.height.equalTo(146)
                            }
                            tableView.endUpdates()
                        } else {
                            cell.makeUpButton.isHidden = true
                            cell.rescheduleButton.isHidden = true
                            cell.cancelButton.isHidden = true
                            cell.line.isHidden = true
                            lesson._isOpen = false
                            cell.mainView.snp.updateConstraints { make in
                                make.height.equalTo(96)
                            }
                            tableView.endUpdates()
                        }
                    } else {
                        if cell.rescheduleButton.isHidden {
                            cell.rescheduleButton.isHidden = false
                            cell.cancelButton.isHidden = false
                            cell.line.isHidden = false
                            lesson._isOpen = true
                            cell.mainView.snp.updateConstraints { make in
                                make.height.equalTo(146)
                            }
                            tableView.endUpdates()
                        } else {
                            cell.rescheduleButton.isHidden = true
                            cell.cancelButton.isHidden = true
                            cell.makeUpButton.isHidden = true
                            cell.line.isHidden = true
                            lesson._isOpen = false
                            cell.mainView.snp.updateConstraints { make in
                                make.height.equalTo(96)
                            }
                            tableView.endUpdates()
                        }
                    }

                    if opendIndex != -1 {
                        if opendIndex == cell.tag {
                            opendIndex = -1
                            return
                        }
                        lessonSchedule[opendIndex]._isOpen = false
                        tableView.reloadRows(at: [IndexPath(row: opendIndex, section: 0)], with: .none)
                    }
                    opendIndex = cell.tag
                }
            }
        }
    }

    func allFuturesCellSchedule(clickButton cell: AllFuturesCell, isLeftButton isCancel: Bool) {
        guard let lesson = modules[cell.tag].lesson else { return }
        let data = lesson
        logger.debug("点击按钮,当前数据: \(data.toJSONString() ?? "")")
        if data.teacherId == "" {
            if isCancel {
                // 删除课程
                guard let config = ListenerService.shared.studentData.scheduleConfigs.filter({ $0.id == data.lessonScheduleConfigId }).first else { return }

                if config.repeatType == .none {
                    SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Go back", rightButtonString: "Delete") {
                    } rightButtonAction: { [weak self] in
                        guard let self = self else { return }
                        LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                            .done { _ in
                                self.hideFullScreenLoading()
                                self.tableView.reloadData()
                                self.initData()
                                TKToast.show(msg: "Removed this lesson successfully")
                            }
                            .catch { _ in
                                self.hideFullScreenLoading()
                                TKToast.show(msg: "Remove failed, try again later", style: .error)
                            }
                    }
                } else {
                    SL.Alert.show(target: self, title: "Warning", message: "Are you sure you want to delete this lesson?", leftButttonString: "Only this lesson", centerButttonString: "This and upcoming lessons", rightButtonString: "Go back") { [weak self] in
                        guard let self = self else { return }
                        self.showFullScreenLoading()
                        LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: false)
                            .done { _ in
                                self.hideFullScreenLoading()
                                self.tableView.reloadData()
                                self.initData()
                                TKToast.show(msg: "Removed this lesson successfully")
                            }
                            .catch { _ in
                                self.hideFullScreenLoading()
                                TKToast.show(msg: "Remove failed, try again later", style: .error)
                            }
                    } centerButtonAction: { [weak self] in
                        guard let self = self else { return }
                        self.showFullScreenLoading()
                        LessonService.lessonSchedule.studentDeleteLessonWithoutTeacher(data: data, deleteUpcoming: true)
                            .done { _ in
                                self.hideFullScreenLoading()
                                self.initData()
                                TKToast.show(msg: "Removed this lesson successfully")
                            }
                            .catch { _ in
                                self.hideFullScreenLoading()
                                TKToast.show(msg: "Remove failed, try again later", style: .error)
                            }
                    } rightButtonAction: {
                    }
                }

            } else {
                if studentData.studentApplyStatus == .apply {
                    CommonsService.shared.studentReinviteTeacher()
//                    showFullScreenLoadingNoAutoHide()
//                    UserService.user.getUserInfo(id: studentData.teacherId)
//                        .done { [weak self] user in
//                            guard let self = self else { return }
//                            self.hideFullScreenLoading()
//                            TKAlert.show(target: self, title: "Resend", message: "Do you want to resend the invitation", buttonString: "RESEND") {
//                                TKToast.show(msg: "Resent invite to \(user.email)", style: .success)
//                                CommonsService.shared.studentInviteTeacherEmailTemplate(teacherId: user.userId)
//                            }
//                        }
//                        .catch { [weak self] _ in
//                            guard let self = self else { return }
//                            logger.error("获取用户信息失败")
//                            self.hideFullScreenLoading()
//                            TKAlert.show(target: self, title: "Resend", message: "Do you want to resend the invitation", buttonString: "RESEND") {
//                                TKToast.show(msg: "Resent invite successfully", style: .success)
//                                CommonsService.shared.studentInviteTeacherEmailTemplate(teacherId: self.studentData.teacherId)
//                            }
//                        }

                } else {
                    // 添加老师
                    let controller = SInviteTeacherViewController()
                    controller.delegate = self
                    controller.modalPresentationStyle = .custom
                    present(controller, animated: false, completion: nil)
                }
            }
        } else {
            if isCancel {
                cancelLesson(cell: cell)
            } else {
                rescheduleLesson(cell: cell)
            }
            if lessonSchedule.count > opendIndex {
                lessonSchedule[opendIndex]._isOpen = false
            }
            tableView.reloadRows(at: [IndexPath(row: opendIndex, section: 0)], with: .none)
            opendIndex = -1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return lessonSchedule.count
        modules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: - 分割module返回cell,并且对应event cell需要有颜色
        let module = modules[indexPath.row]
        switch module.type {
        case .lesson:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AllFuturesCell.self), for: indexPath) as! AllFuturesCell
            cell.tag = indexPath.row
            let locationInfo = locationInfos[module.lesson!.id] ?? ""
            cell.initData(data: module.lesson!, df: df, locationInfo: locationInfo)
            cell.delegate = self
            return cell
        case .studioEvents:
            let cell = tableView.dequeueReusableCell(withIdentifier: UpcomingStudioEventsTableViewCell.id, for: indexPath) as! UpcomingStudioEventsTableViewCell
            cell.tableView = tableView
            cell.event = module.event
            let color: UIColor
            if let studio = ListenerService.shared.studentData.studioData {
                let colorString = studio.storefrontColor
                if colorString.isEmpty {
                    color = ColorUtil.main
                } else {
                    color = UIColor(hex: colorString)
                }
            } else {
                color = ColorUtil.main
            }
            cell.backColor = color
            return cell
        }
    }
}

extension AllFuturesController: SInviteTeacherViewControllerDelegate {
    func sInviteTeacherViewControllerDismissed() {
    }
}

extension AllFuturesController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        UIImage(named: "lesson_empty")!
    }
}

// MARK: - Action

extension AllFuturesController {
    /// 显示cancelLessonAlert
    /// - Parameters:
    ///   - type:  1:不退款也不可以makeup 2:Makeup 3:退款
    ///   - cell:
    ///   - isNoReschedule: 判断是不是正在Reschedule
    private func showCancelLessonAlert(type: Int, _ cell: AllFuturesCell, rescheduleId: String?, isReschedule: Bool = false) {
        // 1:不退款也不可以makeup 2:Makeup 3:退款 4:不可以Cancel
        guard let lesson = modules[cell.tag].lesson else { return }
        hideFullScreenLoading()
        logger.debug("======\(type)")
        var title = ""
        var message = ""
        if !isReschedule {
            if lesson.rescheduled {
                showCancelReschduleAlert(type, cell)
                return
            }
        }

        switch type {
        case 1:
            title = "Cancel lesson?"

            message = "\(TipMsg.cancelNow)"

//            SL.Alert.show(target: self, title: title, message: message, leftButttonString: "GO BACK", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//            }) { [weak self] in
//                guard let self = self else { return }
//                // cancel lesson 了
//                self.addCancellation(type: 1, schedule: self.lessonSchedule[cell.tag], rescheduleId: rescheduleId, isReschedule: isReschedule)
//            }

            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL ANYWAYS"
            controller.leftButtonAction = {
                [weak self] in
                guard let self = self, let lesson = self.modules[cell.tag].lesson else { return }
                self.addCancellation(type: 1, schedule: lesson, rescheduleId: rescheduleId, isReschedule: isReschedule, cell: cell)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)

            break
        case 2:
            title = "Cancel lesson?"
            message = "If you decided to cancel now, you will receive session credit for a later date. "
//            SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//            }) { [weak self] in
//                guard let self = self else { return }
//                // 多了一条MakeUp的信息
//                self.addCancellation(type: 2, schedule: self.lessonSchedule[cell.tag], rescheduleId: rescheduleId, isReschedule: isReschedule)
//            }

            let controller = SL.SLAlert()
            controller.modalPresentationStyle = .custom
            controller.titleString = title
            controller.rightButtonColor = ColorUtil.main
            controller.leftButtonColor = ColorUtil.red
            controller.rightButtonString = "GO BACK"
            controller.leftButtonString = "CANCEL NOW"
            controller.leftButtonAction = { [weak self] in
                guard let self = self, let lesson = self.modules[cell.tag].lesson else { return }
                self.addCancellation(type: 2, schedule: lesson, rescheduleId: rescheduleId, isReschedule: isReschedule, cell: cell)
            }
            controller.rightButtonAction = {
            }
            controller.messageString = message
            controller.leftButtonFont = FontUtil.bold(size: 13)
            controller.rightButtonFont = FontUtil.bold(size: 13)
            present(controller, animated: false, completion: nil)
            break
        case 3:
            guard let lesson = modules[cell.tag].lesson else { return }
            getLessonType(schedule: lesson, isReschedule: isReschedule, rescheduleId: rescheduleId, cell: cell)
            break
        case 4:
            print("=======")
            break
        default:
            break
        }
    }

    /// 点击Cancel 显示该课程正在Reschedule的Alert
    /// - Parameters:
    ///   - type:type: Int, _ cell: AllFuturesCell
    ///   - cell:
    private func showCancelReschduleAlert(_ type: Int, _ cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.getRescheduleByOldScheduleId(oldScheduleId: lesson.id)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    guard docs.from == .server else { return }
                    self.hideFullScreenLoading()

                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count == 0 {
                        SL.Alert.show(target: self, title: "", message: TipMsg.connectionFailed, centerButttonString: "OK") {
                        }
                    } else {
                        if data[0].timeAfter == "" {
                            // 说明是老师发起的Reschedule 学生还未配置时间
                            self.showCancelLessonAlert(type: type, cell, rescheduleId: data[0].id, isReschedule: true)
                        } else {
//                            let df = DateFormatter()
//                            df.dateFormat = "MMM d, hh:mm a"

//                            SL.Alert.show(target: self, title: "Prompt", message: "This lesson is pending on confirmation of rescheduling to \(df.string(from: TimeUtil.changeTime(time: Double(data[0].timeAfter)!))). Would you like to continue to cancel?", leftButttonString: "CANCEL", rightButtonString: "OK", leftButtonAction: {
//                            }) { [weak self] in
//                                self?.showCancelLessonAlert(type: type, cell, rescheduleId: data[0].id, isReschedule: true)
//                            }

                            let controller = SL.SLAlert()
                            controller.modalPresentationStyle = .custom
                            controller.titleString = ""
                            controller.rightButtonColor = ColorUtil.main
                            controller.leftButtonColor = ColorUtil.red
                            controller.rightButtonString = "GO BACK"
                            controller.leftButtonString = "CANCEL ANYWAYS"
                            controller.messageString = "This lession is pending to be rescheduled. Cancel anyways?"
                            controller.leftButtonAction = {
                                [weak self] in
                                guard let self = self else { return }
                                self.showCancelLessonAlert(type: type, cell, rescheduleId: data[0].id, isReschedule: true)
                            }
                            controller.rightButtonAction = {
                            }

                            controller.leftButtonFont = FontUtil.bold(size: 13)
                            controller.rightButtonFont = FontUtil.bold(size: 13)
                            self.present(controller, animated: false, completion: nil)
                        }
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }

                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)

                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getLessonType(schedule: TKLessonSchedule, isReschedule: Bool, rescheduleId: String?, cell: AllFuturesCell) {
        let title = "Cancel lesson?"
        //                        let message = "A $\(doc.price.description) adjustment will be deducted from the balance on your next bill if you decide to cancal this lesson."
        let remainingTime = Date().timestamp + policyData.refundNoticeRequired * 60 * 60
        var hour: CGFloat = CGFloat((schedule.shouldDateTime - Double(remainingTime)) / 60 / 60).roundTo(places: 1)
        var message = "You will receive credit if you cancel within the next \(hour) hours"
        if hour > 24 {
            hour = (hour / 24).roundTo(places: 0)
            message = "You will receive credit if you cancel within the next \(Int(hour)) days"
        }

        let controller = SL.SLAlert()
        controller.modalPresentationStyle = .custom
        controller.titleString = title
        controller.rightButtonColor = ColorUtil.main
        controller.leftButtonColor = ColorUtil.red
        controller.rightButtonString = "GO BACK"
        controller.leftButtonString = "CANCEL NOW"
        controller.messageString = message
        controller.leftButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.addCancellation(type: 3, schedule: schedule, rescheduleId: rescheduleId, isReschedule: isReschedule, cell: cell)
        }
        controller.rightButtonAction = {
        }

        controller.leftButtonFont = FontUtil.bold(size: 13)
        controller.rightButtonFont = FontUtil.bold(size: 13)
        present(controller, animated: false, completion: nil)

//        showFullScreenLoading()
//        var isLaoad = false
//        addSubscribe(
//            LessonService.lessonType.getById(lessonTypeId: schedule.lessonTypeId)
//                .subscribe(onNext: { [weak self] doc in
//                    guard let self = self else { return }
//                    if isLaoad {
//                        return
//                    }
//                    isLaoad = true
//                    self.hideFullScreenLoading()
//
//                    if let doc = TKLessonType.deserialize(from: doc.data()) {
//                        let title = "Cancel lesson?"
//                        let message = "A $\(doc.price.description) adjustment will be deducted from the balance on your next bill if you decide to cancal this lesson."
        ////                        let remainingTime = Date().timestamp + self.policyData.refundNoticeRequired * 60 * 60
        ////                        var hour: CGFloat = CGFloat((schedule.shouldDateTime - Double(remainingTime)) / 60 / 60).roundTo(places: 1)
        ////                        var message = "You will receive credit if you cancel within the next \(hour)  hours"
        ////                        if hour > 24 {
        ////                            hour = (hour / 24).roundTo(places: 0)
        ////                            message = "You will receive credit if you cancel within the next \(Int(hour))  days"
        ////                        }
//                        //self.policyData.
//
//                        SL.Alert.show(target: self, title: title, message: message, leftButttonString: "No", rightButtonString: "Yes", rightButtonColor: ColorUtil.red, leftButtonAction: {
//                        }) {showCancelLessonAlert
//                            self.addCancellation(type: 3, schedule: schedule, rescheduleId: rescheduleId, isReschedule: isReschedule)
//                        }
//                    } else {
//                        TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    }
//
//                }, onError: { [weak self] err in
//                    self?.hideFullScreenLoading()
//                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
//                    logger.debug("获取失败:\(err)")
//                })
//        )
    }

    /// cancell lesson
    /// - Parameter cell:
    private func cancelLesson(cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        showFullScreenLoading()

//        guard !lessonSchedule[cell.tag].cancelled  else {
//            // 说明已经Cancel
//            showCancelLessonAlert(type: 4, cell, rescheduleId: nil)
//            return
//        }
        if lesson.cancelled && !lesson.rescheduled {
            // 说明已经Cancel,并且没有makeup
            showCancelLessonAlert(type: 4, cell, rescheduleId: nil)
            return
        }
        guard policyData.allowMakeup || policyData.allowRefund else {
            // 说明不可以makeup 也不可以 refund
            showCancelLessonAlert(type: 1, cell, rescheduleId: nil)
            return
        }
        func initData(data: [TKRescheduleMakeupRefundHistory]) {
            // 具体流程查看 : https://naotu.baidu.com/file/d01ed378b66e078a52adf8b1877a9791
            if policyData.allowMakeup {
                makeUp(data)
            } else {
                refund(data)
            }
        }

        func refund(_ data: [TKRescheduleMakeupRefundHistory]) {
            // 走到流程中Refunde
            // 判断是否可以Refund
            if policyData.allowRefund {
                var count = 0
                let date = Date()
                let endTime = date.timestamp

                let toDayStart = date.startOfDay

                if policyData.refundLimitTimes {
                    if data.count > 0 {
                        let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                        var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.refundLimitTimesPeriod * 30 * 30 * 24 * 60 * 60))
                        day = day / 60 / 60 / 24
                        let startTime = toDayStart.add(component: .day, value: -day).timestamp
                        for item in data where item.type == .refund {
                            if let time = Int(item.createTime) {
                                if time >= startTime && time <= endTime {
                                    count += 1
                                }
                            }
                        }
                    }
                    // limited times  开启
                    if count < policyData.refundLimitTimesAmount {
                        // 有次数,判断notice Required是否开启
                        if policyData.refundNoticeRequired == 0 {
                            // 关闭状态,显示第三个弹窗
                            showCancelLessonAlert(type: 3, cell, rescheduleId: nil)
                        } else {
                            if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                                //  在规定的时间段内
                                showCancelLessonAlert(type: 3, cell, rescheduleId: nil)
                            } else {
                                showCancelLessonAlert(type: 1, cell, rescheduleId: nil)
                            }
                        }
                    } else {
                        // 没次数
                        showCancelLessonAlert(type: 1, cell, rescheduleId: nil)
                    }

                } else {
                    // limited times  没有开启,此处需要判断notice Required是否开启
                    if policyData.refundNoticeRequired == 0 {
                        // 关闭状态,显示第三个弹窗
                        showCancelLessonAlert(type: 3, cell, rescheduleId: nil)
                    } else {
                        if (endTime + (policyData.refundNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                            //  在规定的时间段内
                            showCancelLessonAlert(type: 3, cell, rescheduleId: nil)
                        } else {
                            showCancelLessonAlert(type: 1, cell, rescheduleId: nil)
                        }
                    }
                }

            } else {
                // 不支持Refund
                showCancelLessonAlert(type: 1, cell, rescheduleId: nil)
            }
        }
        func makeUp(_ data: [TKRescheduleMakeupRefundHistory]) {
            // 走到流程中 makeup
            var count = 0
            let date = Date()
            let endTime = date.timestamp

            let toDayStart = date.startOfDay

            if policyData.makeupLimitTimes {
                if data.count > 0 {
                    let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                    var day = ((toDayStart.timestamp - firstRescheduleTime) % (policyData.refundLimitTimesPeriod * 30 * 30 * 24 * 60 * 60))
                    day = day / 60 / 60 / 24

                    let startTime = toDayStart.add(component: .day, value: -day).timestamp
                    for item in data where item.type == .makeup {
                        if let time = Int(item.createTime) {
                            if time >= startTime && time <= endTime {
                                count += 1
                            }
                        }
                    }
                }
                // limited times  开启
                if count < policyData.makeupLimitTimesAmount {
                    // 有次数,判断notice Required是否开启
                    if policyData.makeupNoticeRequired == 0 {
                        // 关闭状态,显示第二个弹窗
                        showCancelLessonAlert(type: 2, cell, rescheduleId: nil)
                    } else {
                        if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                            //  在规定的时间段内,显示第二个弹窗
                            showCancelLessonAlert(type: 2, cell, rescheduleId: nil)
                        } else {
                            // 不在时间段内, 走 refund流程
                            refund(data)
                        }
                    }
                } else {
                    // 没次数,走refund 流程
                    refund(data)
                }

            } else {
                // limited times  没有开启,此处需要判断notice Required是否开启
                if policyData.makeupNoticeRequired == 0 {
                    // 关闭状态,显示第二个弹窗
                    showCancelLessonAlert(type: 2, cell, rescheduleId: nil)
                } else {
                    if (endTime + (policyData.makeupNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                        //  在规定的时间段内,显示第二个弹窗
                        showCancelLessonAlert(type: 2, cell, rescheduleId: nil)
                    } else {
                        // 不在时间段内, 走 refund流程
                        refund(data)
                    }
                }
            }
        }
        var teacherId: String = studentData.teacherId
        if studentData.studentApplyStatus == .apply {
            teacherId = ""
        }
        addSubscribe(
            UserService.teacher.getRescheduleMakeupRefundHistory(type: [.makeup, .refund], teacherId: teacherId, studentId: studentData.studentId)
                .subscribe(onNext: { docs in
                    guard docs.from == .server else {
                        return
                    }
                    var data: [TKRescheduleMakeupRefundHistory] = []
                    for doc in docs.documents {
                        if let doc = TKRescheduleMakeupRefundHistory.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }

                    initData(data: data)

                }, onError: { [weak self] err in
                    guard let self = self else {
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    private func getReschdeuleData(_ cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        showFullScreenLoading()
        addSubscribe(
            LessonService.lessonSchedule.getRescheduleByOldScheduleId(oldScheduleId: lesson.id)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    guard docs.from == .server else { return }
                    self.hideFullScreenLoading()

                    var data: [TKReschedule] = []
                    for doc in docs.documents {
                        if let doc = TKReschedule.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count == 0 {
                        SL.Alert.show(target: self, title: "", message: "\(TipMsg.notAllowRescheduling)", centerButttonString: "OK") {
                        }
                    } else {
                        if data[0].timeAfter == "" {
                            // 说明是老师发起的Reschedule 学生还未配置时间
                            let controller = RescheduleController(originalData: lesson, rescheduleData: data[0], buttonType: .cancelLesson, policyData: self.policyData, isEdit: false)
                            controller.modalPresentationStyle = .fullScreen
                            controller.hero.isEnabled = true
                            controller.enablePanToDismiss()
                            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                            self.present(controller, animated: true, completion: nil)
                        } else {
//                            let df = DateFormatter()
//                            df.dateFormat = "MMM d, hh:mm a"

//                            SL.Alert.show(target: self, title: "Prompt", message: "This lesson is pending on confirmation of rescheduling to \(df.string(from: TimeUtil.changeTime(time: Double(data[0].timeAfter)!))), would you like to reschedule a new time?", leftButttonString: "CANCEL", rightButtonString: "OK", leftButtonAction: {
//                            }) {
//                                // 修改新的时间
//                                let controller = RescheduleController(originalData: self.lessonSchedule[cell.tag], rescheduleData: data[0], buttonType: .reschedule, policyData: self.policyData, isEdit: true)
//                                controller.modalPresentationStyle = .fullScreen
//                                controller.hero.isEnabled = true
//                                controller.enablePanToDismiss()
//                                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
//                                self.present(controller, animated: true, completion: nil)
//                            }

                            let controller = SL.SLAlert()
                            controller.modalPresentationStyle = .custom
                            controller.titleString = ""
                            controller.rightButtonColor = ColorUtil.main
                            controller.leftButtonColor = ColorUtil.red
                            controller.rightButtonString = "GO BACK"
                            controller.leftButtonString = "TO RESCHEDULE"
                            controller.messageString = "This lession is pending to be rescheduled. reschedule anyways? "
                            controller.leftButtonAction = {
                                [weak self] in
                                guard let self = self else { return }
                                let controller = RescheduleController(originalData: lesson, rescheduleData: data[0], buttonType: .reschedule, policyData: self.policyData, isEdit: true)
                                controller.modalPresentationStyle = .fullScreen
                                controller.hero.isEnabled = true
                                controller.enablePanToDismiss()
                                controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                                self.present(controller, animated: true, completion: nil)
                            }
                            controller.rightButtonAction = {
                            }

                            controller.leftButtonFont = FontUtil.bold(size: 13)
                            controller.rightButtonFont = FontUtil.bold(size: 13)
                            self.present(controller, animated: false, completion: nil)
                        }
                    }
                }, onError: { [weak self] err in
                    guard let self = self else { return }

                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)

                    logger.debug("获取失败:\(err)")
                })
        )
    }

    /// reschedule 课程
    /// - Parameter cell
    private func rescheduleLesson(cell: AllFuturesCell) {
        guard let lesson = modules[cell.tag].lesson else { return }
        showFullScreenLoading()

        func openNoRescheduleAlert(_ type: Int) {
            hideFullScreenLoading()

            // 1:正在reschedule, 2:不允许reschedule, 3:不在规定时间范围内, 4:次数不够
            switch type {
            case 1:
                if lesson.rescheduleLessonData != nil {
                    if lesson.rescheduleLessonData!.senderId == lesson.rescheduleLessonData!.teacherId {
                        let controller = RescheduleController(originalData: lesson, rescheduleData: lesson.rescheduleLessonData!, buttonType: .cancelLesson, policyData: policyData, isEdit: false, isMianController: false)
                        controller.modalPresentationStyle = .fullScreen
                        controller.hero.isEnabled = true
                        controller.enablePanToDismiss()
                        controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
                        present(controller, animated: true, completion: nil)
                    } else {
                        getReschdeuleData(cell)
                    }
                } else {
                    getReschdeuleData(cell)
                }

                break
            case 2:

                SL.Alert.show(target: self, title: "Reschedule lesson?", message: "\(TipMsg.notAllowRescheduling1)", centerButttonString: "OK") {
                }

                break
            case 3:

                SL.Alert.show(target: self, title: "", message: "Rescheduling is discouraged beyond \(policyData.rescheduleNoticeRequired) hours before the lesson. You may still cancel, but not receive a refund or any credit. ", centerButttonString: "OK") {
                }
                break
            case 4:
//                SL.Alert.show(target: self, title: "Prompt", message: "You already rescheduled \(policyData.rescheduleLimitTimesAmount) times in passed \(policyData.rescheduleLimitTimesPeriod) month, According to the studio's policy, you can't reschedule.", centerButttonString: "OK") {
//                }
                /**
                 4:
                 Your instructor's policies allow reschedules per_month(s).
                 You have passed this limit and can NOT rechedule until 07/2.
                 However, you can cancel the lesson.
                 */
//                SL.Alert.show(target: self, title: "Prompt", message: "Your instructor's policies allow \(policyData.rescheduleLimitTimesAmount) reschedules per \(policyData.rescheduleLimitTimesPeriod) month. You have passed this limit and can NOT rechedule. However, you can cancel the lesson.", leftButttonString: "GO BACK", rightButtonString: "CANCEL INSTEAD", leftButtonColor: ColorUtil.main, rightButtonColor: ColorUtil.red, leftButtonAction: {
//                }) { [weak self] in
//
//                    self?.cancelLesson(cell: cell)
//                }
                let controller = SL.SLAlert()
                controller.modalPresentationStyle = .custom
                controller.titleString = "Oops!"
                controller.rightButtonColor = ColorUtil.main
                controller.leftButtonColor = ColorUtil.red
                controller.rightButtonString = "GO BACK"
                controller.leftButtonString = "CANCEL INSTEAD"
                controller.leftButtonAction = { [weak self] in
                    self?.cancelLesson(cell: cell)
                }
                controller.rightButtonAction = {
                }
                controller.messageString = "Your instructor's policies allow \(policyData.rescheduleLimitTimesAmount) reschedule\(policyData.rescheduleLimitTimesAmount <= 1 ? "" : "s") per \(policyData.rescheduleLimitTimesPeriod) month\(policyData.rescheduleLimitTimesPeriod <= 1 ? "" : "s"). You have passed this limit and can NOT reschedule. However, you can cancel the lesson."
                controller.leftButtonFont = FontUtil.bold(size: 13)
                controller.rightButtonFont = FontUtil.bold(size: 13)
                present(controller, animated: false, completion: nil)

                break
            default:
                break
            }
        }
        func openRescheduleController() {
            hideFullScreenLoading()

            let controller = RescheduleController(originalData: lesson, buttonType: .reschedule, policyData: policyData)
            controller.modalPresentationStyle = .fullScreen
            controller.hero.isEnabled = true
            controller.enablePanToDismiss()
            controller.hero.modalAnimationType = .selectBy(presenting: .push(direction: .left), dismissing: .pull(direction: .right))
            present(controller, animated: true, completion: nil)
        }
        guard !lesson.rescheduled else {
            // 正在Reschedule 中
            openNoRescheduleAlert(1)
            return
        }
        guard policyData.allowReschedule else {
            // 不允许Reschedule
            openNoRescheduleAlert(2)
            return
        }
        guard policyData.rescheduleLimitTimes else {
            let time = Date().timestamp

            if policyData.rescheduleNoticeRequired != 0 {
                if (time + (policyData.rescheduleNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                    // 说明 时间大于规定可reschedule 的时间

                    openRescheduleController()

                } else {
                    // 说明 时间小于规定可reschedule 的时间
                    openNoRescheduleAlert(3)
                }

            } else {
                // 说明 可以无限reschedule 并且 只要在开课之前就可以Reschedule
                openRescheduleController()
            }

            return
        }
        var teacherId: String = studentData.teacherId
        if studentData.studentApplyStatus == .apply {
            teacherId = ""
        }
        addSubscribe(
            UserService.teacher.getRescheduleMakeupRefundHistory(type: [.reschedule], teacherId: teacherId, studentId: studentData.studentId)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else {
                        return
                    }
                    guard docs.from == .server else {
                        return
                    }
                    var data: [TKRescheduleMakeupRefundHistory] = []
                    for doc in docs.documents {
                        if let doc = TKRescheduleMakeupRefundHistory.deserialize(from: doc.data()) {
                            data.append(doc)
                        }
                    }
                    if data.count > 0 {
                        let date = Date()
                        let toDayStart = date.startOfDay
                        let firstRescheduleTime = TimeUtil.changeTime(time: Double(data[0].createTime)!).startOfDay.timestamp
                        var day = ((toDayStart.timestamp - firstRescheduleTime) % (self.policyData.rescheduleLimitTimesPeriod * 30 * 24 * 60 * 60))
                        day = day / 60 / 60 / 24
                        let startTime = toDayStart.add(component: .day, value: -day).timestamp
                        let endTime = date.timestamp
                        var count = 0
                        for item in data {
                            if let time = Int(item.createTime) {
                                if time >= startTime && time <= endTime {
                                    count += 1
                                }
                            }
                        }
                        if count < self.policyData.rescheduleLimitTimesAmount {
                            if self.policyData.rescheduleNoticeRequired != 0 {
                                if (endTime + (self.policyData.rescheduleNoticeRequired * 60 * 60)) <= Int(lesson.shouldDateTime) {
                                    // 说明有剩余次数 且 在规定的时间段内
                                    openRescheduleController()
                                } else {
                                    openNoRescheduleAlert(3)
                                }
                            } else {
                                // 说明 可以无限reschedule 并且还有剩余次数
                                openRescheduleController()
                            }
                        } else {
                            // 次数不够
                            openNoRescheduleAlert(4)
                        }

                    } else {
                        openRescheduleController()
                    }

                }, onError: { [weak self] err in
                    guard let self = self else {
                        return
                    }
                    self.hideFullScreenLoading()
                    TKToast.show(msg: TipMsg.connectionFailed, style: .warning)
                    logger.debug("获取失败:\(err)")
                })
        )
    }
}

extension AllFuturesController {
    private func onAddLessonTapped() {
        PopSheet().items([
            .init(title: "Join Group Lesson", action: { [weak self] in
                self?.joinGroupLesson()
            }),
            .init(title: "Add Private Lesson", action: { [weak self] in
                self?.addPrivateLesson()
            }),
        ])
        .show()
    }

    private func addPrivateLesson() {
        guard let student = ListenerService.shared.studentData.studentData else { return }
        let controller = StudioAddLessonForStudentViewController(student)
        controller.skipSteps = [.addInstructors, .addStudent, .selectStudent]
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
    }

    private func joinGroupLesson() {
        let controller = StudioGroupLessonSelectorViewController()
        controller.modalPresentationStyle = .custom
        Tools.getTopViewController()?.present(controller, animated: false)
        controller.onGroupLessonSelected = { lessons in
            guard let lesson = lessons.first else { return }
            let controller = GroupLessonJoinViewController(lessonScheduleConfigId: lesson.id)
            controller.modalPresentationStyle = .custom
            Tools.getTopViewController()?.present(controller, animated: false)
        }
    }
}

protocol AllFuturesControllerDelegate: NSObjectProtocol {
    func allFuturesController(clickPendingLesson id: String)
}
