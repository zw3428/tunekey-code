//
//  InsightsTeachingViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import HandyJSON
import UIKit

class InsightsTeachingViewController: TKBaseViewController {
    struct WorkHours: HandyJSON {
        var workHoursData: [Int] = []
    }

    weak var delegate: InsightsCalendarFilterViewDelegate?

    private var workHoursLabel: TKLabel!
    private var workHoursView: TKView!
    private var segmentedView: UISegmentedControl!

    private var capacityLabel: TKLabel!
    private var capacityView: TKView!

    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var workHoursData: [Int] = [Int](repeating: 8, count: 7)
    private var lessonSchedule: [TKLessonSchedule] = []
    private var scheduleConfigs: [TKLessonScheduleConfigure] = []
    private var lessonTypes: [TKLessonType] = []
    var startTimestamp: Int = 0
    private var endTimestamp: Int = 0

    private var leftLockView: TKImageView!
    private var rightLockView: TKImageView!
    private var segmentedShadowView: TKView!
    private var policiesData: TKPolicies?

    var status: InsightsDataChartCollectionViewCell.Status = .weekly
    var currentDate = Date()

    var hoursData: [CGFloat] = [CGFloat](repeating: 0, count: 7)
    var capacityData: [CGFloat] = [CGFloat](repeating: 0, count: 7)
    var totalHour = 0
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
    private let weeklyStartRangeTime = Date().add(component: .day, value: -6).startOfDay.timestamp
    private let weeklyEndRangeTime = Date().endOfDay.timestamp
    // 用来存储已经存到本地的lesson
    private var lessonScheduleIdMap: [String: String] = [:]
    // 用来存储已经存到网络的lesson
    private var webLessonScheduleMap: [String: Bool] = [:]
    private var teacherID = UserService.user.id() ?? ""

    override func onViewAppear() {
        super.onViewAppear()
        teacherID = UserService.user.id() ?? ""
//        if Tools.isOverrightInsightsViewCount() {
//            showLockView()
//        } else {
//            hideLockView()
//        }

        if delegate?.insightsCalendarFilterViewIsShow() ?? false {
            showCalendarFilterView(animated: false)
        } else {
            hideCalendarFilterView(animated: false)
        }
    }
}

extension InsightsTeachingViewController {
    // MARK: - Data

    override func initData() {
//        startTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).timestamp
//        endTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).add(component: .day, value: 7).timestamp - 1
//        let json: String = SLCache.main.get(key: SLCache.TEACHING_WORK_HOUR)
//        if let workHours = WorkHours.deserialize(from: json) {
//            workHoursData = workHours.workHoursData
//        }
        teacherID = UserService.user.id() ?? ""
        refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
        getPolicies()
        EventBus.listen(key: .refreshPolicy, target: self) { [weak self] _ in
            self?.getPolicies()
        }
    }

    func getPolicies() {
        showFullScreenLoading()
        var isLoad = false
        addSubscribe(
            UserService.teacher.getPolicies()
                .timeout(RxTimeInterval.seconds(TIME_OUT_TIME), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    if let data = data[true] {
                        isLoad = true
                        self.policiesData = data
                        if data.lessonHours.count >= 7 {
                            self.workHoursData = data.lessonHours
                        }
                        self.getLessonType()
                    }
                    if !isLoad {
                        if let data = data[false] {
                            self.policiesData = data
                            if data.lessonHours.count >= 7 {
                                self.workHoursData = data.lessonHours
                            }
                            self.getLessonType()
                        }
                    }

                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.hideFullScreenLoading()
                    self.getLessonType()
                    logger.debug("=失败了=====\(err)")
                })
        )
    }

    func refreshData(startRangeDate: Date, endRangeDate: Date) {
        self.startRangeDate = startRangeDate
        self.endRangeDate = endRangeDate
        webLessonScheduleMap.removeAll()
        lessonScheduleIdMap.removeAll()
        lessonSchedule = []

        let count = TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate) + 1
        hoursData = [CGFloat](repeating: 0, count: count)
        capacityData = hoursData
        initLessonSchedule()
    }

    func refreshData(startTimestamp: Int) {
        self.startTimestamp = startTimestamp
        endTimestamp = Date().add(component: .year, value: 1).timestamp
        hoursData = [CGFloat](repeating: 0, count: TimeUtil.getApartDay(startTime: startTimestamp, endTime: endTimestamp) + 1)
        capacityData = hoursData
        getLessonType()
    }

    func reloadData(_ teacherMemberLevel: Int) {
        self.teacherMemberLevel = teacherMemberLevel
    }

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
//        LessonService.lessonSchedule.refreshLessonSchedule(startTime: startTimestamp, endTime: endTimestamp )
//            .done {[weak self] _ in
//                guard let self = self else { return }
//            }
//            .catch { error in
//                logger.error("刷新课程失败: \(error)")
//            }

        let sortData = ScheduleUtil.getSchedule(startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
        for sortItem in sortData.enumerated() {
            let id = "\(sortItem.element.teacherId):\(sortItem.element.studentId):\(Int(sortItem.element.shouldDateTime))"
            sortData[sortItem.offset].id = id
            if lessonScheduleIdMap[id] == nil {
                lessonSchedule.append(sortItem.element)
                lessonScheduleIdMap[id] = id
            }
        }
        self.refreshView()
        netWorkLesson(localData: sortData)

//
//        addSubscribe(
//            LessonService.lessonSchedule.getScheduleList(teacherID: teacherID, startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp, isCache: true)
//                .subscribe(onNext: { [weak self] docs in
//                    guard let self = self else { return }
//                    var data: [TKLessonSchedule] = []
//
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
        totalHour = 0
        hoursData = [CGFloat](repeating: 0, count: hoursData.count)
        capacityData = [CGFloat](repeating: 0, count: hoursData.count)
        for item in lessonSchedule {
//            if item.shouldDateTime >= Double(weeklyStartRangeTime) && item.shouldDateTime <= Double(weeklyEndRangeTime) {
//                if let lessonType = item.lessonTypeData {
//                    totalHour = totalHour + lessonType.timeLength
//                }
//            }
            if item.getShouldDateTime() >= Double(startRangeDate.timestamp) && item.getShouldDateTime() <= Double(endRangeDate.timestamp) {
                if let lessonType = item.lessonTypeData {
                    totalHour = totalHour + lessonType.timeLength
                }
            }
            let shouldDate = TimeUtil.changeTime(time: item.getShouldDateTime())

            let index = TimeUtil.getApartDay(startData: startRangeDate, endData: shouldDate.startOfDay)

            if index >= 0 && index < hoursData.count {
                hoursData[index] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
                var capactity: CGFloat = 1
                if workHoursData[shouldDate.getWeekday()] != 0 {
                    capactity = CGFloat(CGFloat(CGFloat(item.shouldTimeLength) / 60) / CGFloat(workHoursData[shouldDate.getWeekday()]))
                }

                capacityData[index] += CGFloat(Int(capactity * 100))
            }
        }

        collectionView.reloadData()

        workHoursLabel.text("0")
        capacityLabel.text("0")

        if totalHour != 0 {
            totalHour = totalHour / 60
            let difference: CGFloat = CGFloat(TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate)) + 1
            let avgHour: CGFloat = (CGFloat(totalHour) * CGFloat(7)) / difference

            workHoursLabel.text("\(avgHour.roundTo(places: 1))")
            var workTotalHour: CGFloat = 0
            workHoursData.forEach { item in
                workTotalHour += CGFloat(item)
            }

            if workTotalHour != 0 {
                let capactity = CGFloat(avgHour / CGFloat(workTotalHour)) * 100
                if capactity > 0.1 {
                    capacityLabel.text("\(capactity.roundTo(places: 1))")
                } else {
                    capacityLabel.text("0.1")
                }
            } else {
                capacityLabel.text("100")
            }
            // 总时间显示的算法
//            totalHour = totalHour / 60
//            workHoursLabel.text("\(totalHour)")
//            let workTotalHour = TimeUtil.getTotalWorkHour(startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp, workHour: workHoursData)
//            if workTotalHour != 0 {
//                let capactity = CGFloat(CGFloat(totalHour) / CGFloat(workTotalHour))
//                capacityLabel.text("\(Int(capactity * 100))")
//            }else{
//                capacityLabel.text("100")
//            }

            logger.debug("\(totalHour)======\(workTotalHour)")
        }
    }

//    private func initLessonSchedule() {
//        logger.debug("======startTimestamp:\(startTimestamp)==endTimestamp\(endTimestamp)")
//        lessonSchedule = ScheduleUtil.getSchedule(startTime: startTimestamp, endTime: endTimestamp, data: scheduleConfigs, lessonTypes: lessonTypes)
//
//        totalHour = 0
//        let startDate = TimeUtil.changeTime(time: Double(startTimestamp))
//
//        for item in lessonSchedule {
//            if let lessonType = item.lessonTypeData {
//                totalHour = totalHour + lessonType.timeLength
//            }
//            let shouldDate = TimeUtil.changeTime(time: item.shouldDateTime)
//            let capactity = CGFloat(CGFloat(item.shouldTimeLength) / CGFloat(workHoursData[shouldDate.getWeekday()] * 60))
//            switch status {
//            case .weekly:
//                if TimeUtil.getApartDay(startData: startDate, endData: shouldDate) >= 0 {
//                    print("====\(TimeUtil.getApartDay(startData: startDate, endData: shouldDate))")
//                    hoursData[TimeUtil.getApartDay(startData: startDate, endData: shouldDate)] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
//
//                    capacityData[TimeUtil.getApartDay(startData: startDate, endData: shouldDate)] += CGFloat(Int(capactity * 100))
//                }
    ////                hoursData[shouldDate.getWeekday()] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
    ////                let capactity = CGFloat(CGFloat(item.shouldTimeLength) / CGFloat(workHoursData[shouldDate.getWeekday()] * 60))
    ////                capacityData[shouldDate.getWeekday()] += CGFloat(Int(capactity * 100))
//                break
//            case .monthly:
    ////                if TimeUtil.changeTime(time: item.shouldDateTime).day - 1 >= 0 {
    ////                    hoursData[shouldDate.day - 1] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
    ////                    let capactity = CGFloat(CGFloat(item.shouldTimeLength) / CGFloat(workHoursData[shouldDate.getWeekday()] * 60))
    ////
    ////                    capacityData[shouldDate.day - 1] += CGFloat(Int(capactity * 100))
    ////                }
//
//                if TimeUtil.getApartDay(startData: startDate, endData: shouldDate) >= 0 {
//                    let monthly = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: shouldDate)) / Float(3))
//                    print("\(TimeUtil.getApartDay(startData: startDate, endData: shouldDate))==\(monthly)===\(hoursData.count)")
//                    hoursData[monthly] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
//                    capacityData[monthly] += CGFloat(Int(capactity * 100))
//                }
//
//                break
//            case .quarterly:
    ////                if TimeUtil.getApartDay(startData: startDate, endData: shouldDate) >= 0 {
    ////                    hoursData[TimeUtil.getApartDay(startData: startDate, endData: shouldDate)] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
    ////                    let capactity = CGFloat(CGFloat(CGFloat(item.shouldTimeLength) / 60) / CGFloat(workHoursData[shouldDate.getWeekday()]))
    ////                    capacityData[TimeUtil.getApartDay(startData: startDate, endData: shouldDate)] += CGFloat(Int(capactity * 100))
    ////                }
//                if TimeUtil.getApartDay(startData: startDate, endData: shouldDate) >= 0 {
//                    let monthly = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: shouldDate)) / Float(7))
//
//                    hoursData[monthly] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
//                    capacityData[monthly] += CGFloat(Int(capactity * 100))
//                }
//                break
//            case .annually:
//
    ////                let capactity = CGFloat(CGFloat(CGFloat(item.shouldTimeLength) / 60) / CGFloat(workHoursData[shouldDate.getWeekday()]))
    ////
    ////                var dayFor15 = lroundf(Float(TimeUtil.changeTime(time: item.shouldDateTime).dayOfYear) / Float(30.4375))
    ////
    ////                if dayFor15 <= 0 {
    ////                    dayFor15 = 1
    ////                } else if dayFor15 > 12 {
    ////                    dayFor15 = 12
    ////                }
    ////                hoursData[dayFor15 - 1] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
    ////                capacityData[dayFor15 - 1] += CGFloat(Int(capactity * 100))
//                if TimeUtil.getApartDay(startData: startDate, endData: shouldDate) >= 0 {
//                    let monthly = lroundf(Float(TimeUtil.getApartDay(startData: startDate, endData: shouldDate)) / Float(30))
//
//                    hoursData[monthly] += CGFloat(CGFloat(item.shouldTimeLength) / 60)
//                    capacityData[monthly] += CGFloat(Int(capactity * 100))
//                }
//                break
//            }
//        }
    ////        if status == .annually {
    ////            for item in capacityData.enumerated() {
    ////                capacityData[item.offset] = CGFloat(Int(item.element * 100))
    ////            }
    ////        }
//        collectionView.reloadData()
//
//        workHoursLabel.text("0")
//        capacityLabel.text("0")
//
//        if totalHour != 0 {
//            totalHour = totalHour / 60
//            workHoursLabel.text("\(totalHour)")
//            let workTotalHour = TimeUtil.getTotalWorkHour(startTime: startTimestamp, endTime: endTimestamp, workHour: workHoursData)
//
//            let capactity = CGFloat(CGFloat(totalHour) / CGFloat(workTotalHour))
//            capacityLabel.text("\(Int(capactity * 100))")
//            logger.debug("\(totalHour)======\(workTotalHour)")
//        }
//    }
}

extension InsightsTeachingViewController {
    // MARK: - View

    override func initView() {
        initSegmentedView()
        initWorkHoursView()
        initCapacityView()
        initCollectionView()
        initMemberLevelView()
        hideCalendarFilterView()
    }

    private func initMemberLevelView() {
        guard workHoursView != nil else { return }
        if leftLockView == nil {
            leftLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: workHoursView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalToSuperview().offset(10)
                })
        }
        if rightLockView == nil {
            rightLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: capacityView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalToSuperview().offset(10)
                })
        }
        if teacherMemberLevel == 1 && insightsCount >= insightsLimitCount {
            rightLockView.isHidden = false
            leftLockView.isHidden = false
            workHoursLabel.isHidden = true
            capacityLabel.isHidden = true
            segmentedView.isUserInteractionEnabled = false
        } else {
            rightLockView.isHidden = true
            leftLockView.isHidden = true
            workHoursLabel.isHidden = false
            capacityLabel.isHidden = false
            segmentedView.isUserInteractionEnabled = true
        }
        collectionView.reloadData()
    }

    private func initWorkHoursView() {
        workHoursView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: UIColor(named: "pink")!, endColor: UIColor(named: "purple")!, direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
//        workHoursView.clipsToBounds = true
        addSubview(view: workHoursView) { make in
//            make.top.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Weekly")
        workHoursView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        workHoursView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        workHoursLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .text(text: "0")
        workHoursView.addSubview(view: workHoursLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.width.greaterThanOrEqualTo(22)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .text(text: "hrs")
        workHoursView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(workHoursLabel.snp.right).offset(5)
        }
    }

    private func initCapacityView() {
        capacityView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: UIColor(named: "red-2")!, endColor: UIColor(named: "orange")!, direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)

        addSubview(view: capacityView) { make in
//            make.top.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.right.equalToSuperview().offset(-20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Capacity")
        capacityView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        capacityView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        capacityLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "0")
        capacityView.addSubview(view: capacityLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.width.greaterThanOrEqualTo(22)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "%")
        capacityView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(capacityLabel.snp.right).offset(5)
        }
        _ = TKImageView.create()
            .setImage(name: "setting2")
            .addTo(superView: capacityView, withConstraints: { make in
                make.size.equalTo(22)
                make.top.equalToSuperview().offset(9.5)
                make.right.equalToSuperview().offset(-9.5)
            })
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
//            let date = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate)))
//            startTimestamp = date.timestamp
//            endTimestamp = date.add(component: .day, value: 7).timestamp - 1
//            hoursData = [CGFloat](repeating: 0, count: 7)
//            capacityData = hoursData
//            initLessonSchedule()

            hoursData = [CGFloat](repeating: 0, count: TimeUtil.getApartDay(startTime: startTimestamp, endTime: endTimestamp) + 1)
            capacityData = hoursData
            initLessonSchedule()
            break
        case 1:
            status = .monthly
//            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "1").timestamp
//            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "\(currentDate.getMonthDay())").timestamp + 86399
//            hoursData = [CGFloat](repeating: 0, count: currentDate.getMonthDay())
//            capacityData = hoursData
//            initLessonSchedule()

            hoursData = [CGFloat](repeating: 0, count: TimeUtil.getApartDay(startTime: startTimestamp, endTime: endTimestamp) / 3 + 2)
            capacityData = hoursData
            initLessonSchedule()

            break
        case 2:
            status = .quarterly
//            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "1", day: "1").timestamp
//            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "12", day: "31").timestamp + 86399
//
//            hoursData = [CGFloat](repeating: 0, count: 12)
//            capacityData = hoursData
//            initLessonSchedule()

            hoursData = [CGFloat](repeating: 0, count: TimeUtil.getApartDay(startTime: startTimestamp, endTime: endTimestamp) / 7 + 2)
            capacityData = hoursData
            initLessonSchedule()

            break
        case 3:
            status = .annually
//            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "1", day: "1").timestamp
//            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "12", day: "31").timestamp + 86399
            ////            hoursData = [CGFloat](repeating: 0, count: (currentDate.year % 4 == 0 && currentDate.year % 100 != 0) || (currentDate.year % 400 == 0) ? 366 : 365)
//
//            hoursData = [CGFloat](repeating: 0, count: 12)
//            capacityData = hoursData
//
//            initLessonSchedule()

            hoursData = [CGFloat](repeating: 0, count: TimeUtil.getApartDay(startTime: startTimestamp, endTime: endTimestamp) / 30 + 2)

            capacityData = hoursData
            initLessonSchedule()
            initLessonSchedule()

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
            make.top.equalTo(capacityView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.register(InsightsDataChartCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self))
    }

    override func bindEvent() {
        capacityView.onViewTapped { [weak self] _ in
            guard let self = self else { return }
            if self.teacherMemberLevel == 2 || self.insightsCount < self.insightsLimitCount {
                self.showWorkHoursSelect()
            }
        }
    }

    private func showWorkHoursSelect() {
        guard policiesData != nil else { return }

        TKPopAction.showSelectWorkHoursController(target: self, defualVaues: workHoursData) { [weak self] value in
            guard let self = self else { return }
            self.workHoursData = value
            self.updataPolicies()
            self.hoursData = [CGFloat](repeating: 0, count: self.hoursData.count)
            self.capacityData = self.hoursData
            self.initLessonSchedule()
        }
    }

    private func updataPolicies() {
        addSubscribe(
            UserService.teacher.updatePolicies(data: ["lessonHours": workHoursData])
                .subscribe(onNext: { _ in
                    EventBus.send(key: .refreshPolicy)
                    logger.debug("=====更新成功=")
                }, onError: { err in
                    logger.debug("=====更新失败=\(err)")
                })
        )
    }
}

extension InsightsTeachingViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: - collectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self), for: indexPath) as! InsightsDataChartCollectionViewCell
        if indexPath.item == 0 {
            cell.loadData(data: hoursData, color: UIColor(named: "purple")!, title: "Hours", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, insightsLimitCount: insightsLimitCount)
        } else {
            cell.loadData(data: capacityData, color: UIColor(named: "red-2")!, title: "Capacity", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, suffix: "%", insightsLimitCount: insightsLimitCount)
        }
        return cell
    }
}

extension InsightsTeachingViewController {
    func showLockView() {
        leftLockView?.isHidden = false
        rightLockView?.isHidden = false
        workHoursLabel?.isHidden = true
        capacityLabel?.isHidden = true
    }

    func hideLockView() {
        leftLockView?.isHidden = true
        rightLockView?.isHidden = true
        workHoursLabel?.isHidden = false
        capacityLabel?.isHidden = false
    }
}

extension InsightsTeachingViewController {
    func showCalendarFilterView(animated: Bool = true) {
        let actions = { [weak self] in
            guard let self = self else { return }
            self.segmentedView?.layer.opacity = 1
            self.segmentedShadowView?.layer.opacity = 1
            self.workHoursView?.snp.remakeConstraints { make in
                make.top.equalTo(self.segmentedView.snp.bottom).offset(20)
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.capacityView?.snp.remakeConstraints { make in
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

            self.workHoursView?.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.capacityView?.snp.remakeConstraints { make in
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
