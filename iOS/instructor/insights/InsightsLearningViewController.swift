//
//  InsightsLearningViewController.swift
//  TuneKey
//
//  Created by Zyf on 2019/9/4.
//  Copyright © 2019年 spelist. All rights reserved.
//

import UIKit
class InsightsLearningViewController: TKBaseViewController {
    weak var delegate: InsightsCalendarFilterViewDelegate?

    private let fixedTopMargin: CGFloat = 20

    // MARK: - isPro: false => top margin: 70 | true => top margin: 26

    var isPro: Bool = false

    private let practicePrimaryColor: UIColor = UIColor(red: 255, green: 123, blue: 1)
    private var practiceLabel: TKLabel!
    private var practiceView: TKView!

    private var segmentedView: UISegmentedControl!
    private var segmentedShadowView: TKView!

    private let achievementsPrimaryColor: UIColor = UIColor(red: 44, green: 251, blue: 183)
    private var achievementsLabel: TKLabel!
    private var achievementsView: TKView!

    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!

    private var assignmentData: [TKPractice] = []
    private var achievementData: [TKAchievement] = []
    private var startTimestamp: Int = 0
    private var endTimestamp: Int = 0
    var currentDate = Date()
    var status: InsightsDataChartCollectionViewCell.Status = .weekly

    var practiceChartData: [CGFloat] = [0, 0, 0, 0, 0, 0, 0]
    var achievementChartData: [CGFloat] = [0, 0, 0, 0, 0, 0, 0]

    var totalHour = 0
    var teacherId = ""
    private var leftLockView: TKImageView!
    private var rightLockView: TKImageView!
    private var studentDatas: [TKLearningStudent] = []
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
    private var studentMap: [String: CGFloat] = [:]
    private var studentIds: [String] = []
    override func onViewAppear() {
        super.onViewAppear()

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

extension InsightsLearningViewController {
    // MARK: - Data

    override func initData() {
//        startTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).timestamp
//        endTimestamp = TimeUtil.changeTime(time: Double(TimeUtil.getWeekFirstDayTimestamp(date: currentDate))).add(component: .day, value: 7).timestamp - 1
        teacherId = UserService.user.id()!
        refreshData(startRangeDate: startRangeDate, endRangeDate: endRangeDate)
        getData()
    }

    func refreshData(startRangeDate: Date, endRangeDate: Date) {
        self.startRangeDate = startRangeDate
        self.endRangeDate = endRangeDate
        let count = TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate) + 1
        practiceChartData = [CGFloat](repeating: 0, count: count)
        achievementChartData = practiceChartData
        if teacherId != "" {
            getData()
        }
    }

    func getData() {
        let json: String = SLCache.main.get(key: SLCache.STUDENT_LIST)
        if let studentData = [TKStudent].deserialize(from: json) as? [TKStudent] {
            if studentData.count > 0 {
                for item in studentData {
                    studentIds.append(item.studentId)
                }
            }
        }

        getAssignmentData()
        getAchievementData()
    }

    func getStudentList() {
        var isLoad = false
        addSubscribe(
            UserService.student.getStudentListForLerning()
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let cacheData = data[true] {
                        self.studentDatas = cacheData
                    }

                    if !isLoad {
                        if let serverData = data[false] {
                            self.studentDatas = serverData
                        }
                    }

                    if !isLoad {
                        isLoad = true
                        self.initStudentData()
                    }

                }, onError: { err in
                    logger.debug("====err==\(err)")
                })
        )
    }

    func initStudentData() {
        for item in studentDatas.enumerated() {
            if studentMap[item.element.studentId] != nil {
                studentDatas[item.offset].practiceHour = studentMap[item.element.studentId]!
            }
            studentDatas[item.offset].achievementCount = 0
        }
        for item in achievementData {
            for j in studentDatas.enumerated() {
                if j.element.studentId == item.studentId {
                    studentDatas[j.offset].achievementCount = studentDatas[j.offset].achievementCount + 1
                }
            }
        }
        print("获取到的学生数据:\(studentDatas.toJSONString(prettyPrint: true) ?? "")")
        collectionView.reloadData()
    }

    func getAssignmentData() {
        guard studentIds.count > 0 else {
            assignmentData = []
            return
        }
        addSubscribe(
            LessonService.lessonSchedule.getPracticeByStudentIdsAndTime(studentIds: studentIds, startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if let data = data[.cache] {
                        self.assignmentData.removeAll()
                        print("=a===\(data.toJSONString(prettyPrint: true) ?? "")")
                        self.assignmentData = data
                        self.initPracticeData()
                    }
                    if let data = data[.server] {
                        self.assignmentData.removeAll()
                        print("==b==\(data.toJSONString(prettyPrint: true) ?? "")")
                        self.assignmentData = data
                        self.initPracticeData()
                    }

                }, onError: { err in
                    logger.debug("=失败=====\(err)")
                })
        )
    }

    func initPracticeData() {
        practiceChartData = [CGFloat](repeating: 0, count: practiceChartData.count)
        studentMap.removeAll()

        var totalTimeLength: CGFloat = 0
        practiceLabel.text("0")

        for item in assignmentData {
            let createDate = TimeUtil.changeTime(time: item.shouldDateTime)

            let index = TimeUtil.getApartDay(startData: startRangeDate, endData: createDate)

            if index >= 0 && index < practiceChartData.count {
                var timeLength: CGFloat = 0
                if (item.totalTimeLength / 60 / 60) > 0 {
                    if (item.totalTimeLength / 60 / 60) < 0.1 {
                        timeLength = 0.1
                    } else {
                        timeLength = item.totalTimeLength / 60 / 60
                    }
                }
                let mapId = "\(item.studentId ?? "")"

                if studentMap[mapId] != nil {
                    studentMap[mapId]! += timeLength
                } else {
                    studentMap[mapId] = timeLength
                }
                totalTimeLength += timeLength

                practiceChartData[index] += timeLength
            }
        }
        collectionView.reloadData()
        // 总时间的显示方法
//        totalTimeLength = totalTimeLength.roundTo(places: 1)
//        if totalTimeLength > 0 {
//            if totalTimeLength < 0.1 {
//                totalTimeLength = 0.1
//            }
//            practiceLabel.text("\(totalTimeLength)")
//        } else {
//            practiceLabel.text("0")
//        }
        let difference: CGFloat = CGFloat(TimeUtil.getApartDay(startData: startRangeDate, endData: endRangeDate)) + 1
        let avgHour: CGFloat = (CGFloat(totalTimeLength) * CGFloat(7)) / difference
        if avgHour > 0 {
            if avgHour > 0.1 {
                practiceLabel.text("\(avgHour.roundTo(places: 1))")
            } else {
                practiceLabel.text("0.1")
            }
        } else {
            practiceLabel.text("0")
        }
        getStudentList()
    }

    func getAchievementData() {
        var isLoad = false
        addSubscribe(
            LessonService.lessonSchedule.getScheduleAchievementByTeacherIdAndInTime(teacherId: teacherId, startTime: startRangeDate.timestamp, endTime: endRangeDate.timestamp)
                .subscribe(onNext: { [weak self] data in
                    guard let self = self else { return }
                    if data.from == .cache {
                        self.achievementData.removeAll()
                        if data.documents.count > 0 {
                            isLoad = true
                            for item in data.documents {
                                if let d = TKAchievement.deserialize(from: item.data()) {
                                    self.achievementData.append(d)
                                }
                            }
                            self.initAchievementData()
                        }
                    }
                    if data.from == .server {
                        if !isLoad {
                            self.achievementData.removeAll()
                            for item in data.documents {
                                if let d = TKAchievement.deserialize(from: item.data()) {
                                    self.achievementData.append(d)
                                }
                            }
                            self.initAchievementData()
                        }
                    }

                }, onError: { err in
                    logger.debug("======\(err)")
                })
        )
    }

    func initAchievementData() {
        achievementChartData = [CGFloat](repeating: 0, count: achievementChartData.count)
        for item in studentDatas.enumerated() {
            print("删除")
            studentDatas[item.offset].achievementCount = 0
        }
        logger.debug("获取到的achievementData: \(achievementData.toJSONString() ?? "")")
        for item in achievementData {
            let createDate = TimeUtil.changeTime(time: item.shouldDateTime)
            let index = TimeUtil.getApartDay(startData: startRangeDate, endData: createDate)
            if index >= 0 && index < achievementChartData.count {
                achievementChartData[index] += 1
            }

            for j in studentDatas.enumerated() {
                if j.element.studentId == item.studentId && item.shouldDateTime >= Double(startRangeDate.timestamp) && item.shouldDateTime <= Double(endRangeDate.timestamp) {
                    studentDatas[j.offset].achievementCount += 1
                }
            }
        }
        var total = 0
        for item in achievementChartData {
            total += Int(item)
        }
        logger.debug("计算出来的所有数据: \(achievementChartData)")
        achievementsLabel.text("\(total)")
        logger.debug("===打印===\(studentDatas.toJSONString(prettyPrint: true) ?? "")")
        collectionView.reloadData()
    }
}

extension InsightsLearningViewController {
    // MARK: -  View

    override func initView() {
        initSegmentedView()
        initPracticeView()
        initAchievementsView()
        initCollectionView()
        initMemberLevelView()
        hideCalendarFilterView()
    }

    private func initMemberLevelView() {
        guard practiceView != nil else { return }
        if leftLockView == nil {
            leftLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: practiceView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalToSuperview().offset(10)
                })
        }

        if rightLockView == nil {
            rightLockView = TKImageView.create()
                .setImage(name: "icLock")
                .addTo(superView: achievementsView, withConstraints: { make in
                    make.size.equalTo(22)
                    make.bottom.equalToSuperview().offset(-10)
                    make.left.equalToSuperview().offset(10)
                })
        }

        if teacherMemberLevel == 1 && insightsCount >= insightsLimitCount {
            rightLockView.isHidden = false
            leftLockView.isHidden = false
            practiceLabel.isHidden = true
            achievementsLabel.isHidden = true
            segmentedView.isUserInteractionEnabled = false

        } else {
            rightLockView.isHidden = true
            leftLockView.isHidden = true
            practiceLabel.isHidden = false
            achievementsLabel.isHidden = false
            segmentedView.isUserInteractionEnabled = true
        }
        collectionView.reloadData()
    }

    private func initPracticeView() {
        practiceView = TKView.create()
            .showShadow()
            .gradientBackgroundColor(startColor: practicePrimaryColor, endColor: UIColor(red: 254, green: 204, blue: 82), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
        addSubview(view: practiceView) { make in
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Practice")
        practiceView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        practiceView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        practiceLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .text(text: "")
        practiceView.addSubview(view: practiceLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.width.greaterThanOrEqualTo(22)
            make.left.equalToSuperview().offset(10)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .text(text: "hrs/wk")
        practiceView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(practiceLabel.snp.right).offset(5)
        }
    }

    private func initAchievementsView() {
        achievementsView = TKView.create()
            .gradientBackgroundColor(startColor: achievementsPrimaryColor, endColor: UIColor(red: 19, green: 199, blue: 146), direction: .leftToRight, size: CGSize(width: (UIScreen.main.bounds.width - 50) / 2, height: 80))
            .corner(size: 8)
            .showShadow()
        addSubview(view: achievementsView) { make in
            make.top.equalTo(segmentedView.snp.bottom).offset(20)
            make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
            make.height.equalTo(80)
            make.right.equalToSuperview().offset(-20)
        }

        let titleLabel = TKLabel.create()
            .font(font: FontUtil.regular(size: 13))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "Awards")
        achievementsView.addSubview(view: titleLabel) { make in
            make.top.left.equalToSuperview().offset(10)
        }

        let lineView = TKView.create()
            .backgroundColor(color: UIColor.white)
        achievementsView.addSubview(view: lineView) { make in
            make.top.equalToSuperview().offset(36.5)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
        }

        achievementsLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 24))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "0")
        achievementsView.addSubview(view: achievementsLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(10)
            make.width.greaterThanOrEqualTo(22)
        }

        let suffixLabel = TKLabel.create()
            .font(font: FontUtil.bold(size: 16))
            .textColor(color: UIColor.white)
            .alignment(alignment: .left)
            .text(text: "total.")
        achievementsView.addSubview(view: suffixLabel) { make in
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(achievementsLabel.snp.right).offset(5)
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
            practiceChartData = [CGFloat](repeating: 0, count: 7)
            achievementChartData = practiceChartData
            getData()

        case 1:
            status = .monthly

            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "1").timestamp
            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "\(currentDate.month)", day: "\(currentDate.getMonthDay())").timestamp + 86399
            practiceChartData = [CGFloat](repeating: 0, count: currentDate.getMonthDay())
            achievementChartData = practiceChartData
            getData()

        case 2:
            status = .quarterly
            startTimestamp = TimeUtil.getQuarterStartTime(date: currentDate)
            endTimestamp = TimeUtil.getQuarterEndTime(date: currentDate)
            practiceChartData = [CGFloat](repeating: 0, count: TimeUtil.getQuarterDay(date: currentDate))
            achievementChartData = practiceChartData
            getData()

        case 3:
            status = .annually
            startTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "1", day: "1").timestamp
            endTimestamp = TimeUtil.getDate(year: "\(currentDate.year)", month: "12", day: "31").timestamp + 86399
            practiceChartData = [CGFloat](repeating: 0, count: (currentDate.year % 4 == 0 && currentDate.year % 100 != 0) || (currentDate.year % 400 == 0) ? 366 : 365)
            achievementChartData = practiceChartData
            getData()

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
            make.top.equalTo(practiceView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.register(InsightsDataChartCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self))
        collectionView.register(InsightsLearningStudentsCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: InsightsLearningStudentsCollectionViewCell.self))
    }
}

extension InsightsLearningViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemSize: CGSize!
        if indexPath.section == 0 {
            if UIScreen.main.bounds.width <= 450 {
                // 小屏幕
                itemSize = CGSize(width: UIScreen.main.bounds.width, height: 220)
            } else {
                itemSize = CGSize(width: (UIScreen.main.bounds.width - 20) / 2, height: 220)
            }
        } else {
            itemSize = CGSize(width: UIScreen.main.bounds.width, height: indexPath.item == 0 ? 144 : 94)
        }
        return itemSize
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return studentDatas.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InsightsDataChartCollectionViewCell.self), for: indexPath) as! InsightsDataChartCollectionViewCell
            if indexPath.item == 0 {
                cell.loadData(data: practiceChartData, color: practicePrimaryColor, title: "Practice", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, insightsLimitCount: insightsLimitCount)
            } else {
                cell.loadData(data: achievementChartData, color: achievementsPrimaryColor, title: "Awards", status: status, startDate: startRangeDate, teacherMemberLevel: teacherMemberLevel, insightsCount: insightsCount, insightsLimitCount: insightsLimitCount)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: InsightsLearningStudentsCollectionViewCell.self), for: indexPath) as! InsightsLearningStudentsCollectionViewCell
            cell.loadData(index: indexPath.item, data: studentDatas[indexPath.item])
            return cell
        }
    }
}

extension InsightsLearningViewController {
    func showLockView() {
        leftLockView?.isHidden = false
        rightLockView?.isHidden = false
        practiceLabel?.isHidden = true
        achievementsLabel?.isHidden = true
    }

    func hideLockView() {
        leftLockView?.isHidden = true
        rightLockView?.isHidden = true
        practiceLabel?.isHidden = false
        achievementsLabel?.isHidden = false
    }
}

extension InsightsLearningViewController {
    func showCalendarFilterView(animated: Bool = true) {
        let actions = { [weak self] in
            guard let self = self else { return }
            self.segmentedView?.layer.opacity = 1
            self.segmentedShadowView?.layer.opacity = 1

            self.practiceView?.snp.remakeConstraints { make in
                make.top.equalTo(self.segmentedView.snp.bottom).offset(20)
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.achievementsView?.snp.remakeConstraints { make in
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

            self.practiceView?.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo((UIScreen.main.bounds.width - 50) / 2)
                make.height.equalTo(80)
                make.left.equalToSuperview().offset(20)
            }
            self.achievementsView?.snp.remakeConstraints { make in
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
