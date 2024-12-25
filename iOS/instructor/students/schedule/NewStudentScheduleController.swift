//
//  NewStudentScheduleController.swift
//  TuneKey
//
//  Created by Wht on 2019/11/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

struct StudentScheduleData {
    var type: NewStudentScheduleController.StudentScheduleType = .uncompleted
    var student: LocalContact!
    var isSelect: Bool = false
//    var lessonTypeData: TKLessonType!
//    var endsType: AddLessonScheduleDetailDoesNotEndTableViewCell.EndsType?
    var lessonScheduleConfigure: TKLessonScheduleConfigure = TKLessonScheduleConfigure()
}

class NewStudentScheduleController: TKBaseViewController {
    enum StudentScheduleType {
        case completed
        case uncompleted
    }

    private var selectTimeController: TKPopSelectScheduleStartTimeController?

    var isShwoSendInvite = false
    var mainView = UIView()
    var navigationBar: TKNormalNavigationBar!
    var collectionView: UICollectionView!
    var tableView: UITableView!
    var selectsView = UIView()
    var collectionViewLayout: UICollectionViewFlowLayout!
    var scrollBarBackView = UIView()
    var nextButton: TKBlockButton!

    var studentDatas: [StudentScheduleData] = []
    var scheduleDatas: [TKLessonScheduleConfigure] = []
    var currentPage = 0
    private lazy var titles: [String] = []
    private lazy var titleMap = [String: BatchSettingScheduleController]()
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

        for item in studentDatas.enumerated() {
            let controller = BatchSettingScheduleController()
            controller.view.backgroundColor = UIColor.white
            controller.view.setTopRadius()
            controller.index = item.offset
            controller.parentController = self
            controller.delegate = self
            titles.append(item.element.student.id)
            titleMap[item.element.student.id] = controller
            addChild(controller)
        }
        return PageViewManager(style: style, titles: titles, childViewControllers: children)
    }()

    var timerForShowScrollIndicator: SLTimer?
    @objc func showScrollIndicatorsInContacts() {
        UIView.animate(withDuration: 0.001) { [weak self] in
            guard let self = self else { return }
            self.collectionView.flashScrollIndicators()
        }
    }

    func startTimerForShowScrollIndicator() {
        timerForShowScrollIndicator = SLTimer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(showScrollIndicatorsInContacts), userInfo: nil, repeats: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 设置滚动条颜色
        if #available(iOS 13, *) {
            (collectionView.subviews[collectionView.subviews.count - 1].subviews[0]).backgroundColor = ColorUtil.main // verticalIndicator
            (collectionView.subviews[collectionView.subviews.count - 2].subviews[0]).backgroundColor = ColorUtil.main // horizontalIndicator

        } else {
            if let verticalIndicator: UIImageView = (collectionView.subviews[collectionView.subviews.count - 1] as? UIImageView) {
                verticalIndicator.image = nil
                verticalIndicator.backgroundColor = ColorUtil.main
            }

            if let horizontalIndicator: UIImageView = (collectionView.subviews[collectionView.subviews.count - 2] as? UIImageView) {
                horizontalIndicator.image = nil
                horizontalIndicator.backgroundColor = ColorUtil.main
            }
        }
        // 设置始终显示滚动条
        startTimerForShowScrollIndicator()
    }

    deinit {
        if timerForShowScrollIndicator != nil {
            timerForShowScrollIndicator!.invalidate()
            timerForShowScrollIndicator = nil
        }
    }

    private var blockData: [TKBlock] = []
    private var eventConfig: [TKEventConfigure] = []
    private let dateFormatter = DateFormatter()

    // 用来存储已经存到本地的lessson
    private var lessonScheduleIdMap: [String: String] = [:]

    // 当前时间段的时间
    private var currentMonthDate: Date!
    // 上一个选择的时间段开始时间
    private var previousStartDate: Date!
    // 上一个选择的时间段结束时间
    private var previousEndDate: Date!
    // 全部获取的日程
    private var lessonSchedule: [TKLessonSchedule] = []

    private var startTimestamp = 0
    private var endTimestamp = 0
    private var scheduleConfigs: [TKLessonScheduleConfigure]!
    private var lessonTypes: [TKLessonType]!
    private let teacherID = UserService.user.id()!
    private var webData: [TKWebCalendar] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - View

extension NewStudentScheduleController {
    override func initView() {
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        mainView.backgroundColor = ColorUtil.backgroundColor

        navigationBar = TKNormalNavigationBar(frame: CGRect.zero, title: "Schedule", target: self)
        mainView.addSubviews(navigationBar, selectsView)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
        }
        initCollectionView()
        initSetUpScheduleController()

        nextButton = TKBlockButton(frame: CGRect.zero, title: "NEXT")
        mainView.addSubview(view: nextButton) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(180)
        }
        nextButton.onTapped { [weak self] _ in
            self?.clickNext()
        }
    }

    func initCollectionView() {
        selectsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.height.equalTo(99)
        }
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSize(width: 100, height: 97)
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        selectsView.addSubview(collectionView)
        collectionView.bounces = false
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(97)
        }
        collectionView.register(BatchSettingScheduleCell.self, forCellWithReuseIdentifier: String(describing: BatchSettingScheduleCell.self))
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = ColorUtil.backgroundColor
        // 滚动条偏移量
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 20, bottom: collectionView.bounds.size.width, right: 20)
        collectionView.insertSubview(scrollBarBackView, at: 0)

        scrollBarBackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(23)
            make.height.equalTo(2)
            make.width.equalTo((100 * studentDatas.count) - 46)
            make.top.equalToSuperview().offset(92)
        }

        if CGFloat(100 * studentDatas.count) >= UIScreen.main.bounds.width {
            scrollBarBackView.isHidden = false
        } else {
            scrollBarBackView.isHidden = true
        }
        scrollBarBackView.backgroundColor = ColorUtil.Button.Background.disabled
    }

    func initSetUpScheduleController() {
        let contentView = pageViewManager.contentView
        mainView.addSubview(pageViewManager.contentView)
        contentView.snp.makeConstraints { maker in
            maker.top.equalTo(scrollBarBackView.snp.bottom).offset(20)
            maker.left.right.bottom.equalToSuperview()
        }
        pageViewManager.contentView.delegate = self
    }
}

// MARK: - CollectionView

extension NewStudentScheduleController: UICollectionViewDelegate, UICollectionViewDataSource, BatchSettingCellDelegate {
    func BatchSettingCell(cell: BatchSettingScheduleCell) {
        studentDatas[currentPage].isSelect = false
        studentDatas[cell.tag].isSelect = true
        collectionView.reloadData()
        currentPage = cell.tag
        collectionView.scrollToItem(at: IndexPath(row: cell.tag, section: 0), at: .centeredHorizontally, animated: true)
        pageViewManager.contentView.collectionView.scrollToItem(at: IndexPath(row: cell.tag, section: 0), at: .centeredHorizontally, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return studentDatas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BatchSettingScheduleCell.self), for: indexPath) as! BatchSettingScheduleCell
        cell.tag = indexPath.row
        cell.initData(localContactData: studentDatas[indexPath.row])
        cell.delegate = self
        return cell
    }
}

// MARK: - pageView

extension NewStudentScheduleController: PageContentViewDelegate {
    func contentView(_ contentView: PageContentView, didEndScrollAt index: Int) {
        if index != currentPage {
            studentDatas[currentPage].isSelect = false
            studentDatas[index].isSelect = true
            collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
            collectionView.reloadItems(at: [IndexPath(row: currentPage, section: 0), IndexPath(row: index, section: 0)])
            currentPage = index
        }
    }

    func contentView(_ contentView: PageContentView, scrollingWith sourceIndex: Int, targetIndex: Int, progress: CGFloat) {
    }
}

// MARK: - Data

extension NewStudentScheduleController {
    override func initData() {
        let d = Date()
        previousStartDate = TimeUtil.startOfMonth(date: d)
        previousEndDate = TimeUtil.endOfMonth(date: d)
        currentMonthDate = TimeUtil.startOfMonth(date: d)
        startTimestamp = TimeUtil.startOfMonth(date: d.add(component: .month, value: -1)).timestamp
        endTimestamp = TimeUtil.endOfMonth(date: d.add(component: .month, value: 1)).timestamp
        getBlockData()
        getEventConfigData()
        getLessonType(isUpdate: false)
    }

    private func initScheduleStudent() {
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) {
            if studentData.count > 0 {
                for item in lessonSchedule.enumerated() where item.element.type == .lesson && lessonSchedule[item.offset].studentData == nil {
                    lessonSchedule[item.offset].id = "\(item.element.teacherId):\(item.element.studentId):\(Int(item.element.shouldDateTime))"
                    if let index = studentData.firstIndex(where: { $0!.studentId == item.element.studentId }) {
                        lessonSchedule[item.offset].studentData = studentData[index]
                    }
                }
            }
        }
    }

    private func getBlockData() {
        var isLoad = false

        addSubscribe(
            LessonService.block.list(teacherId: teacherID)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    var d: [TKBlock] = []
                    for item in data.documents {
                        if let doc = TKBlock.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }
                    if !isLoad {
                        if d.count != 0 {
                            isLoad = true
                            self.initBlockData(data: d)
                        }
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initBlockData(data: [TKBlock]) {
        blockData = data
        logger.debug("BlockDataCount:\(data.count)")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for item in data {
            if lessonScheduleIdMap[item.id] == nil {
                lessonScheduleIdMap[item.id] = item.id
                let schedule = TKLessonSchedule()
                schedule.id = item.id
                schedule.teacherId = item.teacherId
                schedule.startDate = dateFormatter.string(from: TimeUtil.changeTime(time: item.startDateTime))
                schedule.shouldDateTime = item.startDateTime
                schedule.shouldTimeLength = Int((item.endDateTime - item.startDateTime) / 60)
                schedule.blockData = item
                schedule.type = .block
                lessonSchedule.append(schedule)
            }
        }
        getCalendarData(isUpdate: false)
    }

    func getEventConfigData() {
        var isLoad = false
        addSubscribe(
            LessonService.event.list(teacherId: teacherID)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    var d: [TKEventConfigure] = []
                    for item in data.documents {
                        if let doc = TKEventConfigure.deserialize(from: item.data()) {
                            d.append(doc)
                        }
                    }
                    if !isLoad {
                        if d.count != 0 {
                            isLoad = true
                            self.eventConfig = d
                            self.initEventData()
                        }
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    private func initEventData() {
        let sortData = EventUtil.getEvent(startTime: startTimestamp, endTime: endTimestamp, data: eventConfig)
        logger.debug("EventDataCount:\(sortData.count)")
        for item in sortData {
            let id = "\(item.teacherId):\(Int(item.shouldDateTime))"
            if lessonScheduleIdMap[id] == nil {
                lessonSchedule.append(item)
                lessonScheduleIdMap[id] = id
            }
        }
        getCalendarData(isUpdate: false)
    }

    private func getLessonType(isUpdate: Bool) {
        var isLoad = false
        addSubscribe(
            LessonService.lessonType.list()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        if data.count != 0 {
                            isLoad = true
                            self.getScheduleConfig(lessonTypes: data, isUpdate: isUpdate)
                        }
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.getScheduleConfig(lessonTypes: data, isUpdate: isUpdate)
                        }
                    }
                })
        )
    }

    private func getScheduleConfig(lessonTypes: [TKLessonType], isUpdate: Bool) {
        self.lessonTypes = lessonTypes
        addSubscribe(
            UserService.teacher.getScheduleConfigs()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.scheduleConfigs = data
                        self.initLessonSchedule(isUpdate: isUpdate)
                    }
                    if let data = data[false] {
                        self.scheduleConfigs = data
                        self.initLessonSchedule(isUpdate: isUpdate)
                    }

                }, onError: { err in
                    logger.debug("=获取ScheduleConfig失败=====\(err)")
                })
        )
    }

    private func initLessonSchedule(isUpdate: Bool) {
        logger.debug("所有的课程: \(scheduleConfigs.toJSONString() ?? "nil")")

        LessonService.lessonSchedule.refreshLessonSchedule(startTime: startTimestamp, endTime: endTimestamp)
            .done { [weak self] _ in
                guard let self = self else { return }
                self.getWebData(localData: [], isUpdate: true)
            }
            .catch { error in
                logger.error("刷新课程失败: \(error)")
            }

//        let sortData = ScheduleUtil.getSchedule(startTime: startTimestamp, endTime: endTimestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
//
//
//
//
//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startTimestamp, endTime: endTimestamp, isCache: true)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKLessonSchedule] = []
//                    for doc in docs.documents {
//                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
//                            var isNext = false
//                            for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
//                                isNext = true
//                            }
//                            guard isNext else { continue }
//                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
//                            if self.lessonScheduleIdMap[d.id] == nil {
//                                self.lessonScheduleIdMap[d.id] = d.id
//                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
//                                    continue
//                                }
//                                self.lessonSchedule.append(d)
//                            }
//                            data.append(d)
//                        }
//                    }
//                    for sortItem in sortData {
//                        let id = "\(sortItem.teacherId):\(sortItem.studentId):\(Int(sortItem.shouldDateTime))"
//                        // 整理lesson 去除 已经存在在lessonSchedule 中的
//                        if self.lessonScheduleIdMap[id] == nil {
//                            var isCancelOfRescheduled = false
//                            for item in data where sortItem.id == item.id {
//                                if item.cancelled || (item.rescheduled && item.rescheduleId != "") {
//                                    isCancelOfRescheduled = true
//                                }
//                            }
//                            if !isCancelOfRescheduled {
//                                self.lessonSchedule.append(sortItem)
//                                self.lessonScheduleIdMap[id] = id
//                            }
//                        }
//                    }
//                    self.getWebData(localData: sortData, isUpdate: isUpdate)
//                    self.initScheduleStudent()
//                    self.getCalendarData(isUpdate: isUpdate)
//                }, onError: { [weak self] err in
//                    guard let self = self else { return }
//                    logger.debug("获取失败:\(err)")
//                    for sortItem in sortData {
//                        let id = "\(sortItem.teacherId):\(sortItem.studentId):\(Int(sortItem.shouldDateTime))"
//                        if self.lessonScheduleIdMap[id] == nil {
//                            self.lessonSchedule.append(sortItem)
//                            self.lessonScheduleIdMap[id] = id
//                        }
//                    }
//                    self.getWebData(localData: sortData, isUpdate: isUpdate)
//                    self.initScheduleStudent()
//                    self.getCalendarData(isUpdate: isUpdate)
//                })
//        )
    }

    private func getWebData(localData: [TKLessonSchedule], isUpdate: Bool) {
        addSubscribe(
            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startTimestamp, endTime: endTimestamp)
                .subscribe(onNext: { [weak self] docs in
                    guard let self = self else { return }
                    var data: [TKLessonSchedule] = []
                    for doc in docs.documents {
                        if let d = TKLessonSchedule.deserialize(from: doc.data()) {
                            var isNext = false
                            for item in self.scheduleConfigs where item.id == d.lessonScheduleConfigId {
                                isNext = true
                            }
                            guard isNext else { continue }
                            d.initShowData(lessonTypeDatas: self.lessonTypes, lessonScheduleDatas: self.scheduleConfigs)
                            var isHave = false
                            for item in self.lessonSchedule.enumerated().reversed() where item.element.id == d.id {
                                isHave = true
                                if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                    self.lessonSchedule.remove(at: item.offset)
                                } else {
                                    self.lessonSchedule[item.offset].refreshData(newData: d)
                                }
                            }
                            if !isHave {
                                if self.lessonScheduleIdMap[d.id] == nil {
                                    self.lessonScheduleIdMap[d.id] = d.id
                                    if d.cancelled || (d.rescheduled && d.rescheduleId != "") {
                                        continue
                                    }
                                    self.lessonSchedule.append(d)
                                }
                            }
                            data.append(d)
                        }
                    }
                    self.getCalendarData(isUpdate: isUpdate)
                    self.initScheduleStudent()
                    //                           self.weekLessonSchedule.removeAll()

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func getCalendarData(isUpdate: Bool) {
        webData.removeAll()
        for item in lessonSchedule {
            var d = TKWebCalendar()
            d.id = item.id
            d.isOverDay = false
            d.shouldDateTime = Int(item.shouldDateTime) * 1000
            d.shouldTimeLength = item.shouldTimeLength
            if item.type == .lesson {
                d.type = ._private
                if item.studentData != nil {
                    d.name = item.studentData!.name
                } else {
                    d.name = "Lesson"
                }
                d.shouldDateTime = Int(item.getShouldDateTime()) * 1000
            } else if item.type == .block {
                d.type = .block
                d.name = "Block"
            } else if item.type == .event {
                d.type = .event
                d.shouldTimeLength = Int(item.eventConfigData.endDateTime - item.eventConfigData.startDateTime)

                d.name = item.eventConfigData.title
            }
            webData.append(d)
        }
        if isUpdate {
            if let selectTimeController = selectTimeController {
                selectTimeController.upDateCalendarData(data: webData)
            }
        }
    }

    func changeTime(date: Date) {
        //        dateFormatter.dateFormat = "MMM"
        if date.timestamp >= previousStartDate.timestamp && date.timestamp <= previousEndDate.timestamp {
            // 走进到这里说明是在周日历模式 且  不需要加载加一个月的数据
            return
        }
        if currentMonthDate.timestamp <= date.timestamp {
            currentMonthDate = date.add(component: .month, value: 1)
        } else {
            currentMonthDate = date.add(component: .month, value: -1)
        }
        previousStartDate = TimeUtil.startOfMonth(date: date)
        previousEndDate = TimeUtil.endOfMonth(date: date)
        startTimestamp = TimeUtil.startOfMonth(date: currentMonthDate).timestamp
        endTimestamp = TimeUtil.endOfMonth(date: currentMonthDate).timestamp

        logger.debug("======\(currentMonthDate.month)")

        initLessonSchedule(isUpdate: true)
    }

    func showSelectTime(lastTime: TimeInterval, timeLength: Int, selectDate: @escaping (_ date: Date) -> Void) {
        selectTimeController = TKPopSelectScheduleStartTimeController()
        selectTimeController!.modalPresentationStyle = .custom
        if lastTime != 0 {
            selectTimeController!.selectDate = TimeUtil.changeTime(time: lastTime)
        }
        selectTimeController!.data = webData
//        selectTimeController!.addLessonDetailController = self
        selectTimeController!.timeLength = timeLength

        present(selectTimeController!, animated: false) {
        }
        selectTimeController?.onDone({ [weak self] date in
            selectDate(date)
            self?.changeSelectTime(date: date)
        })
        selectTimeController?.onDateChange({ [weak self] date in
            self?.changeTime(date: date)
        })
    }

    func changeSelectTime(date: Date) {
//        lessonScheduleConfigure.startDateTime = TimeInterval(date.timestamp)
//        endsType.endDate = Date(seconds: TimeInterval(date.timestamp), region: .local).timeIntervalSince1970
//        cellCount = 4
//        nextButton.enable()
//        tableView.reloadData()
//        if let cell = recurrenceCell {
//            cell.enableSwitch()
//            cell.selectedDate = Date(seconds: lessonScheduleConfigure.startDateTime)
//            cell.resetData()
//        }
    }
}

// MARK: - Action

extension NewStudentScheduleController: BatchSettingScheduleControllerDelegate {
    func batchSettingSchedule(dataChanged data: TKLessonScheduleConfigure, controller: BatchSettingScheduleController) {
        logger.debug(data.toJSONString(prettyPrint: true) ?? "")
        studentDatas[controller.index].lessonScheduleConfigure = data
        if studentDatas[controller.index].lessonScheduleConfigure.startDateTime != 0 {
            studentDatas[controller.index].type = .completed
            collectionView.reloadItems(at: [IndexPath(row: controller.index, section: 0)])
        }

        for item in studentDatas {
            if item.lessonScheduleConfigure.startDateTime == 0 {
                isShwoSendInvite = false
                break
            }
            isShwoSendInvite = true
        }
        if isShwoSendInvite {
            nextButton.setTitle(title: "SEND INVITE")
        } else {
            nextButton.setTitle(title: "NEXT")
        }
    }

    func clickNext() {
        if isShwoSendInvite {
            showFullScreenLoading()
            let time = "\(Date().timestamp)"
            var lessonSchedules: [TKLessonScheduleConfigure] = []
            for item in studentDatas.enumerated() {
                studentDatas[item.offset].lessonScheduleConfigure.studentId = item.element.student.id
                studentDatas[item.offset].lessonScheduleConfigure.updateTime = time
                studentDatas[item.offset].lessonScheduleConfigure.createTime = time
                studentDatas[item.offset].lessonScheduleConfigure.studentLocalData = item.element.student
                lessonSchedules.append(studentDatas[item.offset].lessonScheduleConfigure)
            }
            var setLessonData: [TKSetLessonScheduleModel] = []
            lessonSchedules.forEach { item in
                var data = TKSetLessonScheduleModel()

                let diff = TimeUtil.getUTCWeekdayDiff(timestamp: Int(item.startDateTime * 1000))
                let weekdays: [Int] = item.repeatTypeWeekDay.compactMap {
                    var i = $0 + diff
                    if i < 0 {
                        i = 6
                    } else if i > 6 {
                        i = 0
                    }
                    return Int(i)
                }
                item.repeatTypeWeekDay = weekdays

                data.lessonScheduleConfig = item
                lessonTypes.forEach { lessonItem in
                    if lessonItem.id == item.lessonTypeId {
                        data.lessonType = lessonItem
                    }
                }
                setLessonData.append(data)
            }
            addSubscribe(
                CommonsService.shared.setLessonScheduleConfig(config: setLessonData, invitedStatusIsinviteAndResend: true)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        EventBus.send(key: .refreshStudents)
                        EventBus.send(EventBus.CHANGE_SCHEDULE)
                        setLessonData.forEach { item in
                            if let studentData = item.lessonScheduleConfig?.studentLocalData {
                                CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: studentData.fullName, email: studentData.email, teacherId: item.lessonScheduleConfig?.teacherId ?? "")
                            }
                            if let studentData = item.lessonScheduleConfig?.studentData {
                                CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: studentData.name, email: studentData.email, teacherId: item.lessonScheduleConfig?.teacherId ?? "")
                            }
                        }
                        self.hideFullScreenLoading()
                        self.dismiss(animated: true, completion: nil)

                    }, onError: { [weak self] err in
                        logger.debug("======\(err)")
                        guard let self = self else { return }
                        self.hideFullScreenLoading()
                        TKToast.show(msg: "Set failed, please try again!", style: .warning)
                    })
            )

//            addSubscribe(
//                UserService.teacher.setScheduleConfigs(scheduleConfigs: lessonSchedules, invitedStatusIsinviteAndResend: true)
//                    .subscribe(onNext: { [weak self] _ in
//                        guard let self = self else { return }
//                        EventBus.send(key: .refreshStudents)
//                        EventBus.send(EventBus.CHANGE_SCHEDULE)
            ////                            if let tacherId = UserService.user.id() {
            ////                                CommonsService.shared.sendEmailNotificatioinForInvitationFromTeacher(studentName: self.studentData.name, email: self.studentData.email, teacherId: tacherId)
            ////                            }
//                        self.hideFullScreenLoading()
//                        self.dismiss(animated: true, completion: nil)
//
//                    }, onError: { [weak self] err in
//                        guard let self = self else { return }
//                        self.hideFullScreenLoading()
//                        logger.debug("===setScheduleConfigs===\(err)")
//                        self.dismiss(animated: true, completion: nil)
//                    })
//            )

        } else {
            var pos = currentPage
            for item in studentDatas.enumerated() {
                if item.element.lessonScheduleConfigure.startDateTime == 0 && currentPage != item.offset {
                    pos = item.offset
                    break
                }
            }
            if pos != currentPage {
                studentDatas[currentPage].isSelect = false
                studentDatas[pos].isSelect = true
                collectionView.scrollToItem(at: IndexPath(row: pos, section: 0), at: .centeredHorizontally, animated: true)
                collectionView.reloadItems(at: [IndexPath(row: currentPage, section: 0), IndexPath(row: pos, section: 0)])
                currentPage = pos
                pageViewManager.contentView.collectionView.scrollToItem(at: IndexPath(row: currentPage, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    }
}
