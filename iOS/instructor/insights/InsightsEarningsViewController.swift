//
//  InsightsEarningsViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit

class InsightsEarningsViewController: TKBaseViewController {
    private let fixedTopMargin: CGFloat = 20

    // MARK: - isPro: false => top margin: 70 | true => top margin: 26

    var isPro: Bool = false

    weak var delegate: InsightsCalendarFilterViewDelegate?

    private let studentsPrimaryColor: UIColor = UIColor(red: 168, green: 127, blue: 255)
    private var studentsLabel: TKLabel!
    private var studentsView: TKView!
    private let earningPrimaryColor: UIColor = UIColor(red: 68, green: 222, blue: 197)
    private var earningsLabel: TKLabel!
    private var earningsView: TKView!
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!

    private var segmentedView: UISegmentedControl!
    private var segmentedShadowView: TKView!

    private var workHours = 8
    private var lessonSchedule: [TKLessonSchedule] = []
    private var scheduleConfigs: [TKLessonScheduleConfigure]!
    private var lessonTypes: [TKLessonType]!
    private var startTimestamp: Int = 0
    private var endTimestamp: Int = 0
    private var prefixLabel: TKLabel!
    var currentDate = Date()
    var status: InsightsDataChartCollectionViewCell.Status = .weekly

    var studentsData: [CGFloat] = [CGFloat](repeating: 0, count: 7)
    var earningsData: [CGFloat] = [CGFloat](repeating: 0, count: 7)

    var totalMoney: Double = 0
    var studentData: [TKStudent] = []
    private var leftLockView: TKImageView!
    private var rightLockView: TKImageView!
    var insightsCount = 0
    // 1是免费 2是收费用户
    var teacherMemberLevel = 1 {
        didSet {
            initMemberLevelView()
        }
    }

    var insightsLimitCount: Int = 10

    var startRangeDate: Date!
    var endRangeDate: Date!

    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lesson
    private var webLessonScheduleMap: [String: Bool] = [:]
    private let teacherID = UserService.user.id()!

    override func onViewAppear() {
        super.onViewAppear()
        if delegate?.insightsCalendarFilterViewIsShow() ?? false {
            showCalendarFilterView(animated: false)
        } else {
            hideCalendarFilterView(animated: false)
        }
    }
}

extension InsightsEarningsViewController {
    // MARK: - Data

    override func initData() {
        startTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).timestamp
        endTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).add(component: .day, value: 7).timestamp - 1
        refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
        getData()
    }

    func refreshData(startRangeDate: Date, endRangeDate: Date) {
        self.startRangeDate = startRangeDate
        self.endRangeDate = endRangeDate
        webLessonScheduleMap.removeAll()
        lessonScheduleIdMap.removeAll()
        lessonSchedule = []
        let count = TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate) + 1
        studentsData = [CGFloat](repeating: 0, count: count)
        earningsData = studentsData
        if scheduleConfigs != nil {
            initLessonSchedule()
            initStudentData()
        }
    }

    func getData() {
        getLessonType()
        getStudentData()
    }

    func getStudentData() {
        addSubscribe(
            UserService.student.getStudentList()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let cacheData = data[true] {
                        self.studentData = cacheData
                    }
                    if let serverData = data[false] {
                        self.studentData = serverData
                    }
                    if self.studentData.count > 0 {
                        self.initStudentData()
                    }
                }, onError: { err in
                    logger.debug("====err==\(err)")
                })
        )
    }

    func initStudentData() {
        var studentChartData: [(time: Date, isActive: Bool)] = []
        var count = 0
        var tempStatus = false
        var tempTimestamp = startRangeDate.timestamp
        var tempD = TimeUtil.changeTime(time: Double(tempTimestamp))
        var studentsCount = 0
        studentsData = [CGFloat](repeating: 0, count: studentsData.count)

        for item in studentData {
            var isHaveActive = false
            count = 0
            tempStatus = false
            tempTimestamp = startRangeDate.timestamp
            tempD = TimeUtil.changeTime(time: Double(tempTimestamp))
            var arr = item.statusHistory
            if arr.count <= 0 {
                continue
            }
            var isLoad = false
            arr = arr.sorted(by: { a, b -> Bool in
                a.changeTime < b.changeTime
            })

            for i in arr.enumerated() {
                var changeDate = TimeUtil.changeTime(time: Double(i.element.changeTime)!)
                changeDate = TimeUtil.getDate(year: "\(changeDate.year)", month: "\(changeDate.month)", day: "\(changeDate.day)")
                if changeDate.timestamp >= startRangeDate.timestamp {
                    if !isLoad {
                        isLoad = true
                        count = i.offset + 1
                    }
                }
                if changeDate.timestamp < startRangeDate.timestamp {
                    tempStatus = i.element.status == .active ? true : false
                }
            }
            print("=====我是Count\(count)")
            while tempTimestamp <= endRangeDate.timestamp {
                tempD = TimeUtil.changeTime(time: Double(tempTimestamp))

                if arr.count > 0 {
                    if count <= arr.count - 1 {
                        var changeDate = TimeUtil.changeTime(time: Double(arr[count].changeTime)!)
                        changeDate = TimeUtil.getDate(year: "\(changeDate.year)", month: "\(changeDate.month)", day: "\(changeDate.day)")
                        if tempTimestamp == changeDate.timestamp {
                            tempStatus = arr[count].status == .active ? true : false
                            count += 1
                        }
                    }
                }

                let d = (time: tempD, isActive: tempStatus)
                studentChartData.append(d)
                if tempStatus {
                    if !isHaveActive {
                        isHaveActive = true
                        studentsCount += 1
                    }

                    switch status {
                    case .weekly:
//                        studentsData[tempD.getWeekday()] += 1
                        let index = TimeUtil.getApartDay(startData: startRangeDate, endData: tempD)
                        print("=======\(index)")
                        if index >= 0 && index < studentsData.count {
                            studentsData[index] += 1
                        }
                        break
                    case .monthly:
                        if tempD.day - 1 >= 0 {
                            studentsData[tempD.day - 1] += 1
                        }
                        break
                    case .quarterly:
                        if TimeUtil.getApartDay(startData: startRangeDate, endData: tempD) >= 0 {
                            studentsData[TimeUtil.getApartDay(startData: startRangeDate, endData: tempD)] += 1
                        }
                        break
                    case .annually:
                        studentsData[tempD.dayOfYear] += 1
                        break
                    }
                }
                tempTimestamp += oneDay
            }
        }
        collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
        studentsLabel.text("0")
        if studentsCount != 0 {
            studentsLabel.text("\(studentsCount)")
        }
    }

    /**
     已知值:
     1. 数组(个数不固定) 顺序为 changeTime从大到小或从小到大 都可以
     2. 起始时间 结束时间 (时间间隔不一定多大 有可能一年 也有可能是一周)

     求: 起始时间到结束时间内 每天的status是 1 还是其他

     例:
     数组为:changeTime :03-01 00:00,status: 1 ||| changeTime: 03-05 00:00 ,status:3 ||| changeTime: 03-08 00:00 ,status:1
     起始时间: 2-25 00:00 结束时间:8-29 23:59

     那么答案应该就是:
     2-25 : false
     2-26 : false
     2-27 : false
     2-28 : false
     2-29 : false
     3-1  : true
     3-2  : true
     3-3  : true
     3-4  : true
     3-5  : false
     3-6  : false
     3-7  : false
     3-8  : true
     3-9  : true
     3-10 : true
     3-11 : true
     3-12 : true
     3-13 : true
     3-14 : true
     3-15 : true
     3-16 : true
     ...因篇幅原因省略...
     ...因篇幅原因省略...
     ...因篇幅原因省略...
     8-29 : true
     */

    private func getLessonType() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonType.list()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        if data.count != 0 {
                            isLoad = true
                            self.getScheduleConfig(lessonTypes: data)
                        }
                    }
                    if let data = data[false] {
                        if !isLoad {
                            self.getScheduleConfig(lessonTypes: data)
                        }
                    }
                })
        )
    }

    private func getScheduleConfig(lessonTypes: [TKLessonType]) {
        self.lessonTypes = lessonTypes
        addSubscribe(
            UserService.teacher.getScheduleConfigs()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[true] {
                        self.scheduleConfigs = data
                        self.initLessonSchedule()
                    }
                    if let data = data[false] {
                        self.scheduleConfigs = data
                        self.initLessonSchedule()
                    }

                }, onError: { err in
                    logger.debug("=获取ScheduleConfig失败=====\(err)")
                })
        )
    }

    private func initLessonSchedule() {
        let sortData = ScheduleUtil.getSchedule(startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
        for sortItem in sortData.enumerated() {
            let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
            sortData[sortItem.offset].id = id
            if lessonScheduleIdMap[id] == nil {
                lessonSchedule.append(sortItem.element)
                lessonScheduleIdMap[id] = id
            }
        }
        refreshView()
        netWorkLesson(localData: [])

//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp, isCache: true)
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
//                                self.lessonSchedule.append(sortItem.element)
//                                self.lessonScheduleIdMap[id] = id
//                            }
//                        }
//                    }
//                    self.refreshView()
//                    self.netWorkLesson(localData: sortData)
//
//                }, onError: { [weak self] err in
//                    guard let self = self else { return }
//                    logger.debug("获取失败:\(err)")
//                    for sortItem in sortData.enumerated() {
//                        let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
//                        sortData[sortItem.offset].id = id
//                        if self.lessonScheduleIdMap[id] == nil {
//                            self.lessonSchedule.append(sortItem.element)
//                            self.lessonScheduleIdMap[id] = id
//                        }
//                    }
//                    self.refreshView()
//                    self.netWorkLesson(localData: sortData)
//
//                })
//        )
    }

    private func netWorkLesson(localData: [TKLessonSchedule]) {
        addSubscribe(
            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp)
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
                    self.refreshView()

                }, onError: { err in
                    logger.debug("获取失败:\(err)")
                })
        )
    }

    func refreshView() {
        totalMoney = 0
        earningsData = [CGFloat](repeating: 0, count: earningsData.count)
        logger.debug("计算钱数 => 开始")
        var lessonIds: [String] = []
        for item in lessonSchedule.filterDuplicates({ $0.id }) {
            let createDate = TimeUtil.changeTime(time: item.getShouldDateTime())
            if let lessonType = item.lessonTypeData {
                lessonIds.append(item.id)
                if let config = item.lessonScheduleData {
                    if config.specialPrice >= 0 {
                        logger.debug("计算钱数 => 累加: \(config.specialPrice) -> 总额: \(totalMoney) -> lesson: \(item.id)")
                        totalMoney += config.specialPrice
                    } else {
                        let price = (lessonType.price.doubleValue == -1 ? 0 : lessonType.price.doubleValue)
                        totalMoney += (lessonType.price.doubleValue == -1 ? 0 : lessonType.price.doubleValue)
                        logger.debug("计算钱数 => 累加: \(price) -> 总额: \(totalMoney) -> lesson: \(item.id)")
                    }
                }
            }
            let index = TimeUtil.getApartDay(startData: startRangeDate, endData: createDate)

            if index >= 0 && index < earningsData.count {
                earningsData[index] += CGFloat(item.lessonTypeData!.price.doubleValue == -1 ? 0 : item.lessonTypeData!.price.doubleValue)
            }
        }
        
        logger.debug("计算钱数 => 结束,总额: \(totalMoney) -> 总课程数量: \(lessonIds.count) | 过滤后: \(lessonIds.filterDuplicates({ $0 }).count)")
        
        collectionView.reloadItems(at: [IndexPath(row: 1, section: 0)])
        earningsLabel.text("0")
        if totalMoney != 0 {
            earningsLabel.text("\(totalMoney)")
        }
    }

//    private func initLessonSchedule() {
//        let startDate = TimeUtil.changeTime(time: Double(startTimestamp))
//        lessonSchedule = ScheduleUtil.getSchedule(startTime: startRangeDate.timestamp, endTime: endTimestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
//
//        totalMoney = 0
//
//        for item in lessonSchedule {
//            let createDate = TimeUtil.changeTime(time: item.shouldDateTime)
//
//            if let lessonType = item.lessonTypeData {
//                totalMoney += lessonType.price.doubleValue
//            }
//            switch status {
//            case .weekly:
//
//                earningsData[createDate.getWeekday()] += CGFloat(item.lessonTypeData!.price.doubleValue)
//                break
//            case .monthly:
//                if createDate.day - 1 >= 0 {
//                    earningsData[createDate.day - 1] += CGFloat(item.lessonTypeData!.price.doubleValue)
//                }
//                break
//            case .quarterly:
//                if TimeUtil.getApartDay(startData: startDate, endData: createDate) >= 0 {
//                    earningsData[TimeUtil.getApartDay(startData: startDate, endData: createDate)] += CGFloat(item.lessonTypeData!.price.doubleValue)
//                }
//
//                break
//            case .annually:
//                earningsData[createDate.dayOfYear - 1] += CGFloat(item.lessonTypeData!.price.doubleValue)
//
//                break
//            }
//        }
//
//        collectionView.reloadItems(at: [IndexPath(row: 1, section: 0)])
//        earningsLabel.text("0")
//        if totalMoney != 0 {
//            earningsLabel.text("\(totalMoney)")
//        }
//    }
}

extension InsightsEarningsViewController {
    // MARK: - view

    override func initView() {
        initSegmentedView()
        initStudentsView()
        initEarningsView()
        initCollectionView()
        initMemberLevelView()
        hideCalendarFilterView()
    }

    private func initMemberLevelView() {
        guard studentsView != nil else { return }
        if leftLockView == nil {
            leftLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: studentsView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalToSuperview().offset(10)
                })
        }
        if rightLockView == nil {
            rightLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: earningsView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalTo(prefixLabel.snp.right).offset(5)
                })
        }

        if teacherMemberLevel == 1 && insightsCount >= insightsLimitCount {
            rightLockView.isHidden = false
            leftLockView.isHidden = false
            studentsLabel.isHidden = true
            earningsLabel.isHidden = true
            segmentedView.isUserInteractionEnabled = false
        } else {
            rightLockView.isHidden = true
            leftLockView.isHidden = true
            studentsLabel.isHidden = false
            earningsLabel.isHidden = false
            segmentedView.isUserInteractionEnabled = true
        }
        collectionView.reloadData()
    }

    private func initStudentsView() {
        studentsView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: studentsPrimaryColor, endColor: UIColor(red: 107, green: 117, blue: 252), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        addSubview(view: studentsView) { make in
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Students")
        studentsView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        studentsView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        studentsLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .text(text: "0")
        studentsView.addSubview(view: studentsLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.width.greaterThanOrEqualTo(22)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .text(text: "avg")
        studentsView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(studentsLabel.snp.right).offset(5)
        }
    }

    private func initEarningsView() {
        earningsView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: earningPrimaryColor, endColor: UIColor(red: 77, green: 189, blue: 247), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        addSubview(view: earningsView) { make in
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.right.equalToSuperview().offset(-20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Earnings")
        earningsView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        earningsView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        prefixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "$")
        earningsView.addSubview(view: prefixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
        }

        earningsLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "0")
        earningsView.addSubview(view: earningsLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(prefixLabel.snp.right).offset(5)

            make.width.greaterThanOrEqualTo(22)
        }
    }

    private func initSegmentedView() {
        let tags = ["Week", "Month", "Quarter", "Year"]
        segmentedView = UISegmentedControl(items: tags)

        if #available(iOS 13.0, *) {
            segmentedView.setBackgroundImage(ColorUtil.backgroundColor.image(CGSize(width: 1, height: 32)), for: .normal, barMetrics: .default)
            segmentedView.setBackgroundImage(ColorUtil.main.image(CGSize(width: 1, height: 32)), for: .selected, barMetrics: .default)
            segmentedView.layer.borderColor = ColorUtil.dividingLine.cgColor
            segmentedView.layer.borderWidth = 1
            segmentedView.selectedSegmentTintColor = ColorUtil.main
        } else {
            // Fallback on earlier versions
            segmentedView.backgroundColor = ColorUtil.backgroundColor
            segmentedView.layer.borderColor = UIColor.white.cgColor
            segmentedView.layer.borderWidth = 1
            segmentedView.backgroundColor = UIColor.white
            segmentedView.tintColor = ColorUtil.main
        }
        segmentedView.setTitleTextAttributes([.foregroundColor: ColorUtil.Font.primary, .font: FontUtil.bold(size: 13)], for: .normal)
        segmentedView.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: FontUtil.bold(size: 13)], for: .selected)
        segmentedShadowView = TKView.create()
            .backgroundColor(color: ColorUtil.backgroundColor)
            .corner(size: 8)
            .showShadow()
            .addTo(superView: view, withConstraints: { make in
                make.top.equalToSuperview()
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.height.equalTo(40)
            })
        addSubview(view: segmentedView) { make in
            make.top.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(40)
        }
        segmentedView.selectedSegmentIndex = 0
        segmentedView.addTarget(self, action: #selector(segmentedChanged(_:)), for: .valueChanged)
    }

    @objc func segmentedChanged(_ segmented: UISegmentedControl) {
        switch segmented.selectedSegmentIndex {
        case 0:
            status = .weekly
            startTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).timestamp
            endTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).add(component: .day, value: 7).timestamp - 1
            studentsData = [CGFloat](repeating: 0, count: 7)
            earningsData = studentsData
            initLessonSchedule()
            initStudentData()
            break
        case 1:
            status = .monthly
            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "1").timestamp
            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "\(currentDate.getMonthDay())").timestamp + 86399
            studentsData = [CGFloat](repeating: 0, count: currentDate.getMonthDay())
            earningsData = studentsData
            initLessonSchedule()
            initStudentData()
            break
        case 2:
            status = .quarterly
            startTimestamp = TimeUtil.getQuarterStartTime(date: currentDate)
            endTimestamp = TimeUtil.getQuarterEndTime(date: currentDate)
            studentsData = [CGFloat](repeating: 0, count: TimeUtil.getQuarterDay(date: currentDate))
            earningsData = studentsData
            initLessonSchedule()
            initStudentData()
            break
        case 3:
            status = .annually
            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "1", day: "1").timestamp
            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "12", day: "31").timestamp + 86399
            studentsData = [CGFloat](repeating: 0, count: (currentDate.year % 4 == 0 && currentDate.year % 100 != 0) || (currentDate.year % 400 == 0) ? 366 : 365)
            earningsData = studentsData
            initLessonSchedule()
            initStudentData()
            break
        default:
            break
        }
    }

    private func initCollectionView() {
        collectionViewLayout = UICollectionViewFlowLayout()
        var itemSize: CGSize!
        if UIScreen.main.bounds.width <= 450 {
            // 小屏幕
            itemSize = CGSize(width: UIScreen.main.bounds.width, height: 220)
        } else {
            itemSize = CGSize(width: (UIScreen.main.bounds.width - 20) / 2, height: 220)
        }
        collectionViewLayout.itemSize = itemSize
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = ColorUtil.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        addSubview(view: collectionView) { make in
            make.top.equalTo(earningsView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.register(InsightsDataChartCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self))
    }
}

extension InsightsEarningsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self), for: indexPath) as! InsightsDataChartCollectionViewCell
        if indexPath.item == 0 {
            cell.loadData(data: studentsData, color: studentsPrimaryColor, title: "Students", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, insightsLimitCount: insightsLimitCount)
        } else {
            cell.loadData(data: earningsData, color: earningPrimaryColor, title: "Earnings", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, insightsLimitCount: insightsLimitCount)
        }
        return cell
    }
}

extension InsightsEarningsViewController {
    func showLockView() {
        leftLockView?.isHidden = false
        rightLockView?.isHidden = false
        studentsLabel?.isHidden = true
        earningsLabel?.isHidden = true
    }

    func hideLockView() {
        leftLockView?.isHidden = true
        rightLockView?.isHidden = true
        studentsLabel?.isHidden = false
        earningsLabel?.isHidden = false
    }
}

extension InsightsEarningsViewController {
    func showCalendarFilterView(animated: Bool = true) {
        let actions = { [weak self] in
            guard let self = self else { return }
            self.segmentedView?.layer.opacity = 1
            self.segmentedShadowView?.layer.opacity = 1
            self.studentsView?.snp.remakeConstraints { make in
                make.top.equalTo(self.segmentedView.snp.bottom).offset(20)
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.earningsView?.snp.remakeConstraints { make in
                make.top.equalTo(self.segmentedView.snp.bottom).offset(20)
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.right.equalToSuperview().offset(-20)
            }
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                actions()
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            actions()
        }
    }

    func hideCalendarFilterView(animated: Bool = true) {
        let actions = { [weak self] in
            guard let self = self else { return }
            self.segmentedView?.layer.opacity = 0
            self.segmentedShadowView?.layer.opacity = 0
            self.studentsView?.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.earningsView?.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.right.equalToSuperview().offset(-20)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                actions()
                self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            actions()
        }
    }
}
